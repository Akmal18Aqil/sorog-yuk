// Tanpa ini, klaim "jalan offline" bohong: antrean memang selamat di
// localStorage, tapi begitu halaman di-reload tanpa sinyal, modul supabase-js
// dari CDN gagal dimuat dan aplikasinya tidak terbuka sama sekali.
const CACHE = 'sorogan-v1';
const SHELL = [
  './', './index.html', './manifest.webmanifest',
  'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm',
];

self.addEventListener('install', (e) => e.waitUntil(
  caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting())));

self.addEventListener('activate', (e) => e.waitUntil(
  caches.keys()
    .then(k => Promise.all(k.filter(x => x !== CACHE).map(x => caches.delete(x))))
    .then(() => self.clients.claim())));

self.addEventListener('fetch', (e) => {
  // Panggilan ke Supabase TIDAK PERNAH di-cache. Nilai basi yang tampil
  // seolah-olah baru jauh lebih berbahaya daripada pesan gagal yang jujur.
  if (new URL(e.request.url).hostname.endsWith('supabase.co')) return;

  e.respondWith((async () => {
    const tersimpan = await caches.match(e.request);
    if (tersimpan) return tersimpan;
    const resp = await fetch(e.request);
    if (resp.ok) (await caches.open(CACHE)).put(e.request, resp.clone());
    return resp;
  })());
});
