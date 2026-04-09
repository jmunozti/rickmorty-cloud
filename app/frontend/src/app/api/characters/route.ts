const API_BACKEND = process.env.API_BACKEND_URL || "http://localhost:8080";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const page = searchParams.get("page") || "1";
  const name = searchParams.get("name");

  try {
    const params = new URLSearchParams({ page });
    if (name) params.set("name", name);

    const res = await fetch(`${API_BACKEND}/characters?${params}`, { cache: "no-store" });
    return Response.json(await res.json());
  } catch {
    return Response.json({ results: [], info: { pages: 1 } }, { status: 502 });
  }
}
