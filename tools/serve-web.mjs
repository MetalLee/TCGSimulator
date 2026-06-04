import { createReadStream, existsSync, statSync } from "node:fs";
import { createServer } from "node:http";
import { extname, join, normalize, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = fileURLToPath(new URL(".", import.meta.url));
const projectRoot = resolve(__dirname, "..");
const webRoot = resolve(projectRoot, "exports", "web");
const port = Number.parseInt(process.env.PORT ?? "8787", 10);
const host = process.env.HOST ?? "127.0.0.1";

const mimeTypes = new Map([
  [".html", "text/html; charset=utf-8"],
  [".js", "text/javascript; charset=utf-8"],
  [".mjs", "text/javascript; charset=utf-8"],
  [".wasm", "application/wasm"],
  [".pck", "application/octet-stream"],
  [".png", "image/png"],
  [".jpg", "image/jpeg"],
  [".jpeg", "image/jpeg"],
  [".svg", "image/svg+xml"],
  [".ico", "image/x-icon"],
  [".json", "application/json; charset=utf-8"],
  [".css", "text/css; charset=utf-8"],
]);

function sendText(response, statusCode, body) {
  response.writeHead(statusCode, {
    "Content-Type": "text/plain; charset=utf-8",
    "Cache-Control": "no-store",
    "Cross-Origin-Opener-Policy": "same-origin",
    "Cross-Origin-Embedder-Policy": "require-corp",
  });
  response.end(body);
}

function getStaticPath(requestUrl) {
  const url = new URL(requestUrl, `http://${host}:${port}`);
  const decodedPath = decodeURIComponent(url.pathname);
  const relativePath = decodedPath === "/" ? "index.html" : decodedPath.slice(1);
  const normalizedPath = normalize(relativePath);
  const absolutePath = resolve(join(webRoot, normalizedPath));
  const webRootPrefix = webRoot.endsWith(sep) ? webRoot : `${webRoot}${sep}`;

  if (absolutePath !== webRoot && !absolutePath.startsWith(webRootPrefix)) {
    return null;
  }

  return absolutePath;
}

function serveStaticFile(request, response) {
  if (!existsSync(webRoot)) {
    sendText(response, 404, "exports/web/ does not exist. Export the Godot Web build first.");
    return;
  }

  const staticPath = getStaticPath(request.url ?? "/");
  if (staticPath === null) {
    sendText(response, 403, "Forbidden");
    return;
  }

  if (!existsSync(staticPath) || !statSync(staticPath).isFile()) {
    sendText(response, 404, "Not found");
    return;
  }

  const contentType = mimeTypes.get(extname(staticPath).toLowerCase()) ?? "application/octet-stream";
  response.writeHead(200, {
    "Content-Type": contentType,
    "Cache-Control": "no-store",
    "Cross-Origin-Opener-Policy": "same-origin",
    "Cross-Origin-Embedder-Policy": "require-corp",
  });
  createReadStream(staticPath).pipe(response);
}

const server = createServer((request, response) => {
  if (request.method !== "GET" && request.method !== "HEAD") {
    sendText(response, 405, "Method not allowed");
    return;
  }

  serveStaticFile(request, response);
});

server.listen(port, host, () => {
  console.log(`Serving ${webRoot}`);
  console.log(`Open http://${host}:${port}/`);
});
