// Minimal service worker — enables PWA install prompt
const CACHE = 'parayana-v1';

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE).then(cache =>
      cache.addAll([
        '/parayana-counter/parayana-counter.html',
        '/parayana-counter/icon.svg',
        '/parayana-counter/manifest.json',
      ])
    )
  );
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', e => {
  // Network first, fall back to cache for the app shell
  e.respondWith(
    fetch(e.request).catch(() => caches.match(e.request))
  );
});
