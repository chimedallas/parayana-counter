// Service Worker — app shell cache + offline support
const CACHE = 'parayana-v3';

const APP_SHELL = [
  '/parayana-counter/parayana-counter.html',
  '/parayana-counter/join.html',
  '/parayana-counter/tracker.html',
  '/parayana-counter/history.html',
  '/parayana-counter/admin.html',
  '/parayana-counter/icon.svg',
  '/parayana-counter/manifest.json',
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE).then(cache => cache.addAll(APP_SHELL))
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
  const url = new URL(e.request.url);

  // For Supabase API calls — network only, never cache
  if (url.hostname.includes('supabase.co') ||
      url.hostname.includes('qrserver.com') ||
      url.hostname.includes('fonts.googleapis.com') ||
      url.hostname.includes('fonts.gstatic.com') ||
      url.hostname.includes('cdn.jsdelivr.net') ||
      url.hostname.includes('unpkg.com')) {
    e.respondWith(fetch(e.request));
    return;
  }

  // App shell: network first, cache fallback
  e.respondWith(
    fetch(e.request)
      .then(res => {
        // Cache successful GET responses for app shell URLs
        if (res.ok && e.request.method === 'GET') {
          const clone = res.clone();
          caches.open(CACHE).then(cache => cache.put(e.request, clone));
        }
        return res;
      })
      .catch(() => caches.match(e.request))
  );
});
