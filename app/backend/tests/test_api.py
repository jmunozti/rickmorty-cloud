import os

os.environ.setdefault("DB_HOST", "localhost")
os.environ.setdefault("DB_USER", "test")
os.environ.setdefault("DB_PASSWORD", "test")
os.environ.setdefault("DB_NAME", "test")

from unittest.mock import MagicMock, patch

from fastapi.testclient import TestClient

from app import app

client = TestClient(app)


class TestHealthCheck:
    def test_healthz_returns_status(self):
        response = client.get("/healthz")
        assert response.status_code in (200, 500)


class TestCharacters:
    @patch("app.http_requests.get")
    def test_list_characters(self, mock_get):
        mock_get.return_value = MagicMock(
            status_code=200,
            json=lambda: {"info": {"pages": 42}, "results": [{"id": 1, "name": "Rick"}]},
        )
        response = client.get("/characters?page=1")
        assert response.status_code == 200
        data = response.json()
        assert "results" in data
        assert len(data["results"]) == 1

    @patch("app.http_requests.get")
    def test_search_characters(self, mock_get):
        mock_get.return_value = MagicMock(
            status_code=200,
            json=lambda: {"info": {"pages": 1}, "results": [{"id": 1, "name": "Rick"}]},
        )
        response = client.get("/characters?name=Rick")
        assert response.status_code == 200
        assert len(response.json()["results"]) == 1

    @patch("app.http_requests.get")
    def test_search_not_found_returns_empty(self, mock_get):
        mock_get.return_value = MagicMock(status_code=404)
        response = client.get("/characters?name=nonexistent")
        assert response.status_code == 200
        assert response.json()["results"] == []

    @patch("app.http_requests.get")
    def test_get_character_by_id(self, mock_get):
        mock_get.return_value = MagicMock(
            status_code=200,
            json=lambda: {"id": 1, "name": "Rick Sanchez"},
        )
        response = client.get("/characters/1")
        assert response.status_code == 200
        assert response.json()["name"] == "Rick Sanchez"

    @patch("app.http_requests.get")
    def test_get_character_not_found(self, mock_get):
        mock_get.return_value = MagicMock(status_code=404)
        response = client.get("/characters/99999")
        assert response.status_code == 404


class TestFavoritesValidation:
    def test_add_favorite_missing_fields(self):
        response = client.post("/favorites", json={})
        assert response.status_code == 422

    def test_add_favorite_missing_name(self):
        response = client.post("/favorites", json={"character_id": 1})
        assert response.status_code == 422

    def test_add_favorite_missing_character_id(self):
        response = client.post("/favorites", json={"name": "Rick"})
        assert response.status_code == 422

    def test_add_favorite_valid_payload(self):
        """Valid payload should return 200 (with DB) or 500 (without DB), never 422."""
        response = client.post("/favorites", json={
            "character_id": 999,
            "name": "Test Character",
            "image": "https://example.com/img.png",
        })
        # 200 if DB is available, 500 if not — but never 422 (validation error)
        assert response.status_code in (200, 500)

    def test_remove_favorite_without_db(self):
        """Delete should return 404 or 500, never crash."""
        response = client.delete("/favorites/999")
        assert response.status_code in (404, 500)

    def test_list_favorites_without_db(self):
        """List should return 200 or 500, never crash."""
        response = client.get("/favorites")
        assert response.status_code in (200, 500)


class TestStats:
    @patch("app.http_requests.get")
    def test_stats_endpoint(self, mock_get):
        mock_get.return_value = MagicMock(
            status_code=200,
            json=lambda: {
                "info": {"count": 826, "pages": 42},
                "results": [
                    {"status": "Alive", "species": "Human", "gender": "Male"},
                    {"status": "Dead", "species": "Alien", "gender": "Female"},
                ],
            },
        )
        response = client.get("/stats")
        assert response.status_code == 200
        data = response.json()
        assert "total" in data
        assert "status" in data
        assert "species" in data
        assert "gender" in data
