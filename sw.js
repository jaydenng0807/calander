const CACHE = "jayden-cal-v11-hub";
const ASSETS = [
  "./",
  "./index.html",
  "./events.json",
  "./timetable.json",
  "./school-status.json",
  "./school-bot-config.json",
  "./debts.json",
  "./manifest.webmanifest"
];

self.addEventListener("install", (e) => {
  e.waitUntil(
    caches.open(CACHE).then((c) => c.addAll(ASSETS)).then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.map((k) => (k === CACHE ? null : caches.delete(k)))))
      .then(() => self.clients.claim())
      .then(() => self.clients.matchAll({ type: "window", includeUncontrolled: true }))
      .then((clients) =>
        Promise.all(
          clients.map((client) => {
            // Force open tabs onto the fresh network-first shell
            if (typeof client.navigate === "function") {
              return client.navigate(client.url).catch(() => {});
            }
            return null;
          })
        )
      )
  );
});

function networkFirst(request) {
  return fetch(request)
    .then((res) => {
      if (res && res.ok) {
        const copy = res.clone();
        caches.open(CACHE).then((c) => c.put(request, copy));
      }
      return res;
    })
    .catch(() =>
      caches.match(request).then((cached) => cached || caches.match("./index.html"))
    );
}

self.addEventListener("fetch", (e) => {
  const req = e.request;
  if (req.method !== "GET") return;

  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;

  const path = url.pathname;
  const isNav = req.mode === "navigate";
  const isHtml =
    isNav ||
    path.endsWith("/") ||
    path.endsWith("/index.html") ||
    path.endsWith("index.html");
  const isJson =
    path.endsWith("events.json") ||
    path.endsWith("timetable.json") ||
    path.endsWith("school-status.json") ||
    path.endsWith("school-bot-config.json") ||
    path.endsWith("debts.json");

  if (isHtml || isJson) {
    e.respondWith(networkFirst(req));
    return;
  }

  // Optional cache for other same-origin assets (manifest, icons, etc.)
  e.respondWith(
    caches.match(req).then((cached) => {
      const network = fetch(req)
        .then((res) => {
          if (res && res.ok) {
            const copy = res.clone();
            caches.open(CACHE).then((c) => c.put(req, copy));
          }
          return res;
        })
        .catch(() => cached);
      return cached || network;
    })
  );
});
