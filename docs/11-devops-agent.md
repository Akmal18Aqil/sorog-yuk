# 11 — DevOps Agent

Build, rilis, hosting, migrasi, PWA. Detail langkahnya di `19-deployment.md`;
dokumen ini berisi kepemilikan dan aturannya.

## Yang dimiliki

`package.json` · `nuxt.config.ts` · `tsconfig.json` · `.claude/launch.json` ·
`.gitignore` · penerapan migrasi ke Supabase · konfigurasi PWA

## Perkakas dan versi yang dipatok

| | Versi | Catatan |
|---|---|---|
| Node | 24.x | |
| Nuxt | ^4.5 | `ssr: false` |
| `@nuxtjs/supabase` | ^2.0 | `redirect: false`, `types` menunjuk `shared/types/database.ts` |
| `@vite-pwa/nuxt` | ^1.1 | `generateSW`, precache aset build saja |
| TypeScript | **`~5.9` — jangan dinaikkan** | TS 7 (port native) belum didukung `vue-tsc` 3.3; `nuxt typecheck` langsung mati (R16) |
| Vitest | ^4 | |

Menaikkan versi apa pun wajib disertai `npm test`, `npm run typecheck`, dan
`npm run build` hijau dalam satu laporan.

## Aturan build

- `npm run generate` → keluaran statis di `.output/public`. Itu artefak rilis.
- **Wajib HTTPS.** Service worker tidak jalan di HTTP biasa (kecuali
  `localhost`), dan tanpa service worker klaim offline-nya bohong.
- Precache hanya aset build (`js, css, html, svg, ico, woff2`) +
  `navigateFallback: '/'`. **Jangan pernah** menambahkan `runtimeCaching` untuk
  host Supabase (R6).
- `postinstall: nuxt prepare` wajib ada — tanpa `.nuxt/tsconfig.*`, Vitest gagal
  memuat tsconfig dan seluruh test mati padahal domainnya tidak salah apa pun.

## Aturan migrasi

- Migrasi bernomor urut, **tidak pernah diedit setelah ter-apply**. Perbaikan =
  migrasi baru.
- File di `db/` harus **cocok dengan yang benar-benar ter-apply** di project.
  Kalau menerapkan lewat MCP/dashboard, tulis file-nya juga di commit yang sama.
  Repo yang berbeda dari database adalah jebakan yang lebih buruk daripada tidak
  punya file sama sekali.
- File `*_check*.sql` **bukan** migrasi — itu skrip verifikasi yang aman diulang
  dan membatalkan dirinya sendiri. Jangan pernah diterapkan sebagai migrasi.
- Setelah semua ustadz terdaftar, **tutup pendaftaran** di Supabase. Itu
  penjaga utamanya sejak kode klaim dihapus (`db/015`).

## Server pengembangan

`.claude/launch.json` → `npm run dev` di port 3000. Jangan menjalankan server
lewat shell mentah; pakai perkakas preview supaya bisa diperiksa.

## Environment

```
SUPABASE_URL=https://<ref>.supabase.co
SUPABASE_KEY=sb_publishable_...
```

Keduanya punya nilai bawaan di `nuxt.config.ts` supaya `npm run dev` langsung
jalan. `.env` ada di `.gitignore`. Kunci `service_role` tidak pernah masuk sini.

## Sebelum rilis

- [ ] `npm test` · `npm run typecheck` · `npm run build` hijau
- [ ] Check SQL yang relevan hijau
- [ ] Semua migrasi di `db/` sudah ter-apply, dan sebaliknya
- [ ] `get_advisors` (security + performance) tidak ada peringatan baru
- [ ] Diuji di HP sungguhan, bukan hanya emulasi lebar layar
- [ ] **Diuji dengan mode pesawat**: buka aplikasi, nilai satu soal, pastikan
      masuk antrean dan terkirim setelah sinyal kembali. Ini fitur utamanya —
      tidak boleh dirilis tanpa dicoba mati sinyal.

## Setelah rilis

Pantau: jumlah item macet di antrean (kalau naik, ada payload yang ditolak
server), dan `query_logs` Supabase untuk error RPC.
