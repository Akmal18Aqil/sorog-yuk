# 19 — Deployment

## Yang perlu ada

- Node 24.x
- Project Supabase (saat ini `unozvswlxqbhqzmlsirl`, region `ap-northeast-1`)
- Hosting statis apa pun **dengan HTTPS**

## Satu setelan Supabase yang wajib diubah manual

Dashboard → **Authentication → Sign In / Providers → Email** → matikan
**Confirm email**.

Tanpa ini, ustadz harus membuka email konfirmasi dulu — di pesantren itu
penghalang nyata, dan sebagian asatidz tidak memakai email aktif.

Setelah keempat ustadz terdaftar: **Authentication → Sign Ups** → matikan
**Allow new users to sign up**. Pintu masuknya tertutup rapat; RLS tetap
penjaga utamanya, ini lapis tambahan.

## Menyiapkan database dari nol

```bash
# 1. Migrasi, berurutan. Lewati berkas *_check*.sql — itu bukan migrasi.
db/001_schema.sql
db/002_seed.sql
db/004_helper_ke_schema_privat.sql
db/005_rpc_simpan_penilaian.sql
db/006_perbaiki_acuan_klaim_ustadz.sql
db/008_kelompok.sql
db/009_seed_kelompok.sql
db/012_kelas_master_data.sql
db/013_tes_offline_dan_kenaikan.sql

# 2. Verifikasi
db/003_check.sql            # urutan rata-rata nilai
db/016_check_hubungkan.sql  # penghubungan identitas + RLS buta total
db/010_check_kalibrasi.sql  # kalibrasi berpasangan
db/014_check_kenaikan.sql   # gerbang kenaikan kelas
```

Setiap check berhasil kalau memunculkan `*_OK_ROLLBACK` — seluruh data ujinya
dibatalkan sendiri.

## Menjalankan lokal

```bash
npm install
npm run dev
```

Kredensial punya nilai bawaan di `nuxt.config.ts`; timpa lewat `.env`:

```
SUPABASE_URL=https://<ref>.supabase.co
SUPABASE_KEY=sb_publishable_...
```

Kunci publishable memang untuk dipublikasikan — yang menjaga data adalah RLS dan
pendaftaran yang ditutup, bukan kerahasiaan kunci ini. Kunci `service_role` tidak masuk
sini.

## Rilis

```bash
npm test && npm run typecheck && npm run build   # gerbang
npm run generate                                 # artefak → .output/public
```

Unggah `.output/public` ke Netlify / Vercel / GitHub Pages.

**HTTPS wajib.** Service worker tidak jalan di HTTP biasa (kecuali `localhost`),
dan tanpa service worker klaim offline-nya bohong: reload tanpa sinyal akan
gagal memuat aplikasi sama sekali.

## Memasang di HP ustadz

Buka tautannya → menu browser → **Add to Home Screen**. Setelah itu terbuka layar
penuh seperti aplikasi biasa (`display: standalone`).

Beri tahu satu hal ke tiap ustadz: **selama bilah kuning di bawah layar tampil,
jangan hapus data browser di HP itu** — masih ada penilaian yang belum terkirim.

## Uji asap setelah rilis

Wajib, dan bukan hanya di emulasi lebar layar:

1. Daftar dengan email + kata sandi, pilih nama Anda dari daftar → masuk.
2. Pilih kelompok, nilai satu santri sampai selesai.
3. **Nyalakan mode pesawat.** Nilai satu soal lagi → bilah kuning muncul.
4. Matikan mode pesawat → bilah hilang sendiri dalam ≤15 detik.
5. Reload halaman **saat mode pesawat aktif** → aplikasi tetap terbuka.
6. Buka Hasil → Cetak leger → bentuknya menyerupai lembar kertas.
7. Buka Kenaikan kelas → daftar termuat.

Langkah 3–5 adalah fitur utamanya. Jangan pernah merilis tanpa mencobanya.

## Setelah mengubah skema

```bash
npx supabase gen types typescript --project-id <ref> > shared/types/database.ts
npm run typecheck
```

Tipe yang tidak diperbarui membuat `typecheck` hijau untuk kode yang salah.

## Pemantauan

- **Jumlah item macet** di bilah antrean. Kalau naik, ada payload yang ditolak
  server — periksa `query_logs`.
- `get_advisors` untuk `security` dan `performance` setelah setiap perubahan DDL.
  Peringatan baru di luar daftar yang disengaja di `10-security-agent.md` wajib
  ditangani.

## Pemulihan

| Masalah | Tindakan |
|---|---|
| Ustadz salah klaim nama | `update ustadz set auth_id = null where nama = '…'` |
| Akun tidak dikenal terdaftar | Hapus user di dashboard; pastikan Sign Ups tertutup |
| Antrean macet karena klaim dicabut | Pulihkan klaimnya; antrean mengirim sendiri |
| Data browser terhapus sebelum terkirim | Tidak bisa dipulihkan. Karena itu bilah kuning ada. |

## Yang belum ada

Belum ada CI. Gerbang dijalankan manual sebelum rilis. Menambahkan CI ada di
`20-roadmap.md` — pemicunya: begitu ada lebih dari satu orang yang commit.
