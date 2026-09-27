# 06 — Backend Agent

Domain murni, database, dan lapisan data.

## Yang dimiliki

```
shared/domain/       nilai.ts · tangga.ts · pembagian.ts · ringkasan.ts
shared/types/        database.ts (generate) · sorogan.ts
app/utils/repo.ts    satu-satunya titik sentuh Supabase
app/utils/antrean.ts antrean kirim offline
db/*.sql             migrasi + check
```

## Aturan menulis domain

- **Nol I/O.** Tanpa `import` dari `app/`, tanpa Supabase, tanpa Vue.
- **Tak berubah (immutable).** `jawab()` dan `mundur()` mengembalikan status
  baru, tidak memutasi. Mesin keadaan tangga harus bisa diuji tanpa merender.
- **Ketergantungan disuntikkan.** `bagikanBK2(bank, perTipe, acak)` menerima
  pengacak sebagai argumen supaya test bisa deterministik.
- **Satu fungsi = satu aturan.** `nilaiSoal` dan `nilaiSesi` dipisah karena
  urutan penggabungannya justru inti aturannya (R2).
- Fungsi `nilaiDatarKeliru()` **sengaja ada** sebagai pembanding di test. Jangan
  dipakai di produksi, jangan dihapus.

## Aturan menulis migrasi

- Satu file per migrasi, bernomor urut, **tidak pernah diedit setelah
  ter-apply**. Perbaikan = migrasi baru (lihat `db/006`).
- Komentar menjelaskan **kenapa**, bukan apa. Kalau ada jebakan, tulis
  jebakannya — `db/006` menjelaskan pengikatan nama plpgsql, dan itu yang
  menyelamatkan orang berikutnya.
- Setiap tabel baru: `enable row level security` **dan** policy-nya, di migrasi
  yang sama. Tabel tanpa policy sama sekali hanya sah kalau memang dimaksudkan
  nol akses API — dan alasannya wajib ditulis di migrasi.
- Acuan di dalam `plpgsql` **wajib berkualifikasi penuh dan benar**. Migrasi yang
  sukses tidak membuktikan apa pun tentang badan plpgsql (R5).
- `search_path = ''` pada semua fungsi, semua acuan ditulis lengkap.
- View pakai `security_invoker = on`.

## Aturan menulis RPC

- Satu panggilan = satu satuan kerja yang bermakna dan **aman diulang**. Antrean
  offline pasti mengirim ulang; itu bukan kasus tepi.
- `SECURITY INVOKER` untuk yang mengubah data, supaya RLS tetap penjaganya.
  `SECURITY DEFINER` hanya untuk yang memang harus menembus RLS
  (`klaim_ustadz`, helper policy) — dan itu harus disebut alasannya.
- Buang tanda tangan lama saat menambah parameter (`drop function ... (sig lama)`).
  Dua versi hidup berdampingan membuat klien lama diam-diam menyimpan data cacat.
- Validasi di trust boundary. Pesan error ditulis untuk **ustadz**, bukan untuk
  pengembang: *"Kode salah atau sudah dipakai."*

## Aturan menulis repo

- Menerima klien sebagai argumen, tidak mengambil sendiri → bisa dipalsukan.
- Sempitkan `text` dari Postgres jadi union domain, dan **lempar error keras**
  kalau ada nilai asing. Itu artinya skema dan aplikasi tidak sinkron, dan harus
  ketahuan saat memuat, bukan di tengah ujian.
- Jangan pernah membocorkan tipe Supabase ke atas. Halaman tidak boleh tahu
  bentuk `PostgrestError`.

## Setelah mengubah skema

```bash
npx supabase gen types typescript --project-id <ref> > shared/types/database.ts
npm run typecheck
```

Tipe yang tidak diperbarui membuat `typecheck` hijau untuk kode yang salah.

## Checklist sebelum menyerahkan

- [ ] Logika non-sepele punya test di `test/` atau check di `db/`
- [ ] RPC baru diuji lewat **panggilan sungguhan** (R5)
- [ ] Tabel baru punya RLS + policy di migrasi yang sama
- [ ] `shared/types/database.ts` diperbarui
- [ ] `npm test` dan `npm run typecheck` hijau
- [ ] Tidak ada kolom `nilai` yang ditambahkan (R1)
- [ ] Agregasi nilai menyebut materi kelas mana (tidak bocor lintas kelas)
