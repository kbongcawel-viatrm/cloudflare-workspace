export default {
  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname === "/health") {
      return Response.json({ status: "ok" });
    }

    return new Response("Cloudflare App Workspace is ready.", {
      headers: { "content-type": "text/plain; charset=utf-8" }
    });
  }
};
