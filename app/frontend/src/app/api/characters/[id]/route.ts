const API_BACKEND = process.env.API_BACKEND_URL || "http://localhost:8080";

export async function GET(_request: Request, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  try {
    const res = await fetch(`${API_BACKEND}/characters/${id}`, { cache: "no-store" });
    return Response.json(await res.json(), { status: res.status });
  } catch {
    return Response.json({ error: "API unavailable" }, { status: 502 });
  }
}
