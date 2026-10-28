'use strict';

const CACHE_PREFIX = 'kinta-pwa-';
const CACHE_NAME = 'kinta-pwa-__KINTA_BUILD_ID__';
const SCOPE_URL = self.registration.scope;
const APP_INDEX_URL = new URL('index.html', SCOPE_URL).href;

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const manifestUrl = new URL('kinta_precache_manifest.json', SCOPE_URL);
    const response = await fetch(manifestUrl, { cache: 'no-store' });
    if (!response.ok) {
      throw new Error(`Could not load KINTA app cache manifest (${response.status}).`);
    }

    const manifest = await response.json();
    const files = Array.isArray(manifest.files) ? manifest.files : [];
    const cache = await caches.open(CACHE_NAME);
    await cache.addAll(files.map((file) => new URL(file, SCOPE_URL).href));
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const names = await caches.keys();
    await Promise.all(names
      .filter((name) => name.startsWith(CACHE_PREFIX) && name !== CACHE_NAME)
      .map((name) => caches.delete(name)));
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;
  if (url.pathname.includes('/api/')) return;
  if (!url.pathname.startsWith(new URL(SCOPE_URL).pathname)) return;

  if (request.mode === 'navigate') {
    event.respondWith((async () => {
      try {
        const response = await fetch(request);
        if (response.ok) return response;
        if (response.status !== 404) return response;
      } catch (_) {
        // Use the cached Flutter entry page when the host is offline.
      }
      return (await caches.match(APP_INDEX_URL)) ||
        new Response('KINTA is not available offline yet.', {
          status: 503,
          headers: { 'Content-Type': 'text/plain; charset=utf-8' },
        });
    })());
    return;
  }

  event.respondWith((async () => {
    const cache = await caches.open(CACHE_NAME);
    const cached = await cache.match(request, { ignoreSearch: true });
    if (cached) return cached;

    try {
      const response = await fetch(request);
      if (response.ok && response.type === 'basic') {
        await cache.put(request, response.clone());
      }
      return response;
    } catch (_) {
      return new Response('This KINTA app resource is not cached yet.', {
        status: 504,
        headers: { 'Content-Type': 'text/plain; charset=utf-8' },
      });
    }
  })());
});