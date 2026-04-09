"""Rick and Morty Explorer API — browse characters and save favorites."""

import logging
import os
from contextlib import contextmanager

import psycopg2
import psycopg2.pool
import requests as http_requests
from fastapi import FastAPI, HTTPException, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from slowapi import Limiter
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger("rickmorty-api")

DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_USER = os.environ.get("DB_USER", "dbadmin")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "changeme")
DB_NAME = os.environ.get("DB_NAME", "appdb")
CORS_ORIGINS = os.environ.get("CORS_ORIGINS", "*").split(",")
RATE_LIMIT = os.environ.get("RATE_LIMIT", "60/minute")
RICK_MORTY_API = "https://rickandmortyapi.com/api"

# Rate limiter
limiter = Limiter(key_func=get_remote_address)

app = FastAPI(
    title="Rick and Morty Explorer API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url=None,
)

app.state.limiter = limiter


@app.exception_handler(RateLimitExceeded)
async def rate_limit_handler(request: Request, exc: RateLimitExceeded):
    return JSONResponse(status_code=429, content={"error": "Too many requests. Please slow down."})


# Security headers middleware
@app.middleware("http")
async def security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()"
    return response


app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_methods=["GET", "POST", "DELETE"],
    allow_headers=["Content-Type"],
)

_pool = None


def _get_pool():
    global _pool
    if _pool is None:
        _pool = psycopg2.pool.SimpleConnectionPool(
            minconn=2, maxconn=10,
            host=DB_HOST, user=DB_USER, password=DB_PASSWORD, database=DB_NAME,
        )
        conn = _pool.getconn()
        try:
            cursor = conn.cursor()
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS favorites (
                    id SERIAL PRIMARY KEY,
                    character_id INTEGER NOT NULL UNIQUE,
                    name VARCHAR(255) NOT NULL,
                    image VARCHAR(500),
                    created_at TIMESTAMP DEFAULT NOW()
                );
            """)
            conn.commit()
            cursor.close()
            logger.info("Table 'favorites' ready")
        finally:
            _pool.putconn(conn)
    return _pool


@contextmanager
def get_db():
    pool = _get_pool()
    conn = pool.getconn()
    try:
        yield conn
    finally:
        pool.putconn(conn)


@app.get("/healthz")
def health_check():
    try:
        with get_db() as conn:
            cur = conn.cursor()
            cur.execute("SELECT 1")
            cur.close()
        return {"status": "ok", "database": "connected"}
    except Exception:
        raise HTTPException(status_code=500, detail="Database unavailable") from None


# --- Rick and Morty proxy endpoints ---

@app.get("/characters")
@limiter.limit(RATE_LIMIT)
def list_characters(request: Request, page: int = 1, name: str | None = Query(None)):
    params: dict = {"page": page}
    if name:
        params["name"] = name
    res = http_requests.get(f"{RICK_MORTY_API}/character", params=params, timeout=5)
    if res.status_code != 200:
        return {"results": [], "info": {"pages": 1}}
    return res.json()


@app.get("/characters/{character_id}")
@limiter.limit(RATE_LIMIT)
def get_character(request: Request, character_id: int):
    res = http_requests.get(f"{RICK_MORTY_API}/character/{character_id}", timeout=5)
    if res.status_code != 200:
        raise HTTPException(status_code=res.status_code, detail="Character not found")
    return res.json()


@app.get("/stats")
@limiter.limit("10/minute")
def get_stats(request: Request):
    """Aggregate stats from the Rick and Morty API."""
    res = http_requests.get(f"{RICK_MORTY_API}/character", params={"page": 1}, timeout=5)
    if res.status_code != 200:
        return {"total": 0, "status": {}, "species": {}, "gender": {}}

    total = res.json().get("info", {}).get("count", 0)

    status_counts: dict[str, int] = {}
    species_counts: dict[str, int] = {}
    gender_counts: dict[str, int] = {}

    for page_num in range(1, 6):
        page_res = http_requests.get(
            f"{RICK_MORTY_API}/character", params={"page": page_num}, timeout=5
        )
        if page_res.status_code != 200:
            break
        for c in page_res.json().get("results", []):
            status_counts[c["status"]] = status_counts.get(c["status"], 0) + 1
            species_counts[c["species"]] = species_counts.get(c["species"], 0) + 1
            gender_counts[c["gender"]] = gender_counts.get(c["gender"], 0) + 1

    return {
        "total": total,
        "status": dict(sorted(status_counts.items(), key=lambda x: -x[1])),
        "species": dict(sorted(species_counts.items(), key=lambda x: -x[1])[:8]),
        "gender": dict(sorted(gender_counts.items(), key=lambda x: -x[1])),
    }


# --- Favorites (stored in PostgreSQL) ---

class FavoriteRequest(BaseModel):
    character_id: int
    name: str
    image: str = ""


@app.get("/favorites")
@limiter.limit(RATE_LIMIT)
def list_favorites(request: Request):
    try:
        with get_db() as conn:
            cur = conn.cursor()
            cur.execute(
                "SELECT character_id, name, image, created_at FROM favorites ORDER BY created_at DESC"
            )
            rows = cur.fetchall()
            cur.close()
            return [
                {"character_id": r[0], "name": r[1], "image": r[2], "created_at": str(r[3])}
                for r in rows
            ]
    except Exception:
        raise HTTPException(status_code=500, detail="Database unavailable") from None


@app.post("/favorites")
@limiter.limit("30/minute")
def add_favorite(request: Request, body: FavoriteRequest):
    try:
        with get_db() as conn:
            cur = conn.cursor()
            cur.execute(
                "INSERT INTO favorites (character_id, name, image) VALUES (%s, %s, %s) "
                "ON CONFLICT (character_id) DO NOTHING",
                (body.character_id, body.name, body.image),
            )
            conn.commit()
            cur.close()
            return {"success": True, "character_id": body.character_id}
    except Exception:
        raise HTTPException(status_code=500, detail="Database unavailable") from None


@app.delete("/favorites/{character_id}")
@limiter.limit("30/minute")
def remove_favorite(request: Request, character_id: int):
    try:
        with get_db() as conn:
            cur = conn.cursor()
            cur.execute("DELETE FROM favorites WHERE character_id = %s", (character_id,))
            conn.commit()
            deleted = cur.rowcount
            cur.close()
            if deleted == 0:
                raise HTTPException(status_code=404, detail="Favorite not found")
            return {"success": True}
    except HTTPException:
        raise
    except Exception:
        raise HTTPException(status_code=500, detail="Database unavailable") from None
