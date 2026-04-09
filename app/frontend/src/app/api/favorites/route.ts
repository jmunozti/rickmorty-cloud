const API_BACKEND = process.env.API_BACKEND_URL || "http://localhost:8080";

export async function GET() {
  try {
    const res = await fetch(`${API_BACKEND}/favorites`, { cache: "no-store" });
    return Response.json(await res.json());
  } catch {
    return Response.json([], { status: 502 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const res = await fetch(`${API_BACKEND}/favorites`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    return Response.json(await res.json(), { status: res.status });
  } catch {
    return Response.json({ error: "API unavailable" }, { status: 502 });
  }
}
