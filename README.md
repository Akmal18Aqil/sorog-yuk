# Sorogan Digital

Pengganti leger kertas tes lisan baca kitab, untuk BK 1 dan BK 2.
Rencana dan alasan tiap keputusan produk ada di [PLAN.md](PLAN.md).

**Stack:** Nuxt 4 (SPA) · TypeScript strict · Supabase Postgres · PWA · Vitest.

---

## Yang membedakan dari kertas

Kertas menyimpan **satu angka per lafad**. Sistem ini menyimpan **verdict tiap
anak-tangga pertanyaan**: benar / dibantu / salah. Dari sana semuanya lahir
sendiri — nilai, profil kelemahan santri, peta kelas, kalibrasi antar penguji —
tanpa kerja tambahan bagi penguji.

| | Kenapa penting |
|---|---|
| Verdict **`dibantu`** | "Ditunjuki dulu baru bisa" adalah realitas sorogan, dan sinyal kemajuan paling informatif. Kertas memaksanya jadi benar atau salah. |
| **Detik** tiap jawaban | Benar dalam 2 detik ≠ benar dalam 20 detik. |
| Langkah **dilewati** | Langkah bersyarat (BK 1 no. 6–7 hanya isim, no. 9 hanya mabni) tidak menghasilkan baris sama sekali — bukan nilai nol. |

---

## Arsitektur

Arah ketergantungan satu arah, dan **domain tidak bergantung pada apa pun**:

```
pages/  ──▶  composables/  ──▶  utils/repo  ──▶  Supabase
                  │
                  └────────▶  shared/domain/   (murni, teruji, nol I/O)
```

| Lapis | Isi | Aturan |
|---|---|---|
| `shared/domain/` | Aturan nilai, mesin tangga, pembagian soal, peringkasan | Murni. Tanpa Vue, tanpa Supabase, tanpa I/O. **Semua diuji.** |
| `shared/types/` | Tipe DB hasil generate + union domain | Batas anti-korupsi |
| `app/utils/repo.ts` | Satu-satunya titik sentuh Supabase | Menerima klien sebagai argumen, bukan mengambil sendiri |
| `app/utils/antrean.ts` | Antrean kirim offline | Factory, bisa diuji dengan klien palsu |
| `app/composables/` | Keadaan reaktif dan penjahitan | Tanpa aturan bisnis |
| `app/components/` | Tampilan | Tanpa akses data |

**Kenapa domain dipisah keras.** Urutan tangga, arti "lewati", dan urutan
rata-rata nilai adalah aturan ilmu alat yang datang dari lembar asatidz —
bukan detail tampilan. Ditaruh di `shared/domain/` supaya bisa diuji tanpa
merender apa pun, dan supaya tidak ikut berubah tiap kali UI dirombak.

### Kelompok

Satu ustadz memegang satu kelompok, dan kelompoknya berganti-ganti.
**Penugasan ustadz→kelompok sengaja tidak disimpan.** Justru karena berputar:
kolom "penanggung jawab" akan basi terus dan menuntut admin merawatnya. Ustadz
memilih kelompok saat memulai sesi, `sesi.kelompok_id` merekamnya, dan riwayat
siapa memegang apa tetap terbaca penuh dari tabel `sesi`. Rotasi jadi gratis.

**Konsekuensi yang mudah luput — kalibrasi penguji jadi rancu.** Membandingkan
rata-rata antar penguji hanya sah kalau mereka menilai santri yang sebanding.
Begitu tiap ustadz memegang satu kelompok, selisihnya bisa murni karena *siapa
yang ia dapat*, bukan *bagaimana ia menilai* — dan angkanya tetap terlihat
meyakinkan sambil menuduh orang yang salah.

Rotasi jugalah yang menyelamatkannya: kalau santri yang sama pernah dinilai
penguji berbeda, perbandingannya bisa **berpasangan** — nilai seorang penguji
atas santri tertentu vs nilai penguji lain atas santri yang sama. Itu yang
dipakai kolom `selisih_terkalibrasi`; selama belum ada irisan, nilainya `null`,
jujur bahwa belum bisa dibandingkan. Dipagari [db/010_check_kalibrasi.sql](db/010_check_kalibrasi.sql),
yang fixture-nya sengaja dibuat agar kedua metrik menunjuk **orang yang berbeda**.

**Batas anti-korupsi.** Di Postgres, `tipe`/`verdict`/`tingkat` adalah `text`
dengan CHECK constraint, jadi TypeScript melihatnya sebagai `string` — dan
`string` membiarkan salah ketik lolos sampai runtime. `repo.ts` mempersempitnya
jadi union dan **melempar error keras** kalau ada nilai asing: artinya migrasi
dan aplikasi tidak sinkron, dan itu harus ketahuan saat memuat, bukan di tengah
ujian.

---

## Mulai pakai

### 1. Ubah satu setelan Supabase (sekali saja)

Dashboard → **Authentication → Sign In / Providers → Email** → matikan
**Confirm email**. Tanpa ini, ustadz harus membuka email konfirmasi dulu, dan
di pesantren itu penghalang nyata.

Selagi di sana: **Authentication → Sign Ups** → setelah keempat ustadz
terdaftar, matikan **Allow new users to sign up**.

### 2. Jalankan

```bash
npm install
npm run dev
```

Kredensial sudah ada nilai bawaan di `nuxt.config.ts`, jadi `npm run dev` jalan
tanpa setup apa pun. Untuk menunjuk ke project Supabase lain, salin templatnya:

```bash
cp .env.example .env
```

Isinya:

```
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_KEY=sb_publishable_xxx
```

Kunci publishable memang untuk dipublikasikan — yang menjaga data adalah RLS
dan pendaftaran yang ditutup, bukan kerahasiaan kunci ini.

### 3. Pasang ke HP

```bash
npm run generate     # keluaran statis di .output/public
```

Unggah ke hosting statis apa pun (Netlify / Vercel / GitHub Pages).
**Harus HTTPS** — service worker tidak jalan di HTTP biasa, kecuali `localhost`.
Di HP: buka linknya → menu browser → **Add to Home Screen**.

### 4. Menghubungkan akun ke nama ustadz

Tiap ustadz: **Daftar** dengan email + kata sandi, lalu **pilih namanya sendiri**
dari daftar. Satu ketukan, tanpa mengetik, permanen. Sebelum terhubung, akun tidak
bisa melihat data santri sama sekali — sudah diuji, bukan asumsi.

> **Karena itu langkah 1 wajib benar-benar dikerjakan.** Penghubungan hanya
> memilih nama, jadi pendaftaran yang masih terbuka berarti siapa pun bisa
> mendaftar lalu memilih nama yang belum terpakai. Yang menjaga data santri
> adalah **pendaftaran tertutup + RLS**, bukan langkah ini.
>
> Nama yang sudah dipakai akun lain tidak bisa diambil alih. Kalau ada yang salah
> pilih: `update ustadz set auth_id = null where nama = '…'`

### 5. Menilai

1. Pilih **kelompok**, **tingkat**, dan **keperluan** (ujian / sorogan harian),
   lalu ketuk santri dari daftar kelompok itu. Yang sudah dinilai hari ini
   bertanda ✓, jadi penguji tahu sudah sampai mana walau tanpa sinyal.
2. **BK 1** — layar menampilkan ibarat, ketuk satu kata untuk dijadikan soal.
   Nol pengetikan Arab. 10 lafad, sama seperti 10 kolom leger kertas.
   **BK 2** — 8 soal dibagikan otomatis, 2 dari tiap tipe, diacak.
3. Tiap anak-tangga: ketuk **Benar / Dibantu / Salah**, atau **Lewati** kalau
   tidak berlaku. Layar maju sendiri.
4. Selesai → **Lihat hasil & leger** → **Cetak leger**.

Cetakan sengaja dibuat semirip lembar kertas: yang membaca menerima format yang
sama seperti biasa, cuma sudah terisi.

---

## Offline

Penilaian **tidak pernah menunggu jaringan**:

- Tiap soal selesai → masuk antrean di `localStorage` seketika.
- Antrean dikirim sendiri saat ada sinyal (juga tiap 15 detik dan saat `online`).
- Data acuan (santri, bank soal, tangga, ibarat) di-cache; sesi tetap jalan penuh.
- **Kemajuan sesi ikut disimpan.** Tanpa ini, reload di tengah sesi membuat
  penomoran soal mulai dari 1 lagi dan menimpa penilaian yang sudah tersimpan —
  menghasilkan rekaman campuran yang tidak ketahuan salahnya.
- Service worker (Workbox) men-cache seluruh shell aplikasi.
- Panggilan Supabase **tidak pernah** di-cache: nilai basi yang tampil seolah
  baru lebih berbahaya daripada pesan gagal yang jujur.
- Setelah 5 kegagalan beruntun, satu item dipindah ke daftar **macet** supaya
  tidak menyumbat sisanya. Datanya tidak dibuang, dan jumlahnya ditampilkan.

RPC `simpan_penilaian` aman diulang, jadi kiriman ulang tidak menggandakan.

> Bilah kuning di bawah layar = masih ada yang belum terkirim.
> Selama itu tampil, **jangan hapus data browser di perangkat tersebut.**

---

## Isi repo

```
app/
  pages/         index (masuk+pilih nama) · mulai (kelompok) · nilai · hasil · kenaikan
  components/    KetukKata · TanggaPertanyaan · SantriBaris · KesiapanRingkas · BilahAntrean
  composables/   useUstadz · useAcuan · useSesi
  utils/         repo.ts · antrean.ts · tanggal.ts
  middleware/    ustadz.ts
  plugins/       antrean.client.ts   (satu antrean untuk seluruh aplikasi)
  assets/css/    main.css
shared/
  domain/        nilai · tangga · pembagian · ringkasan      ← murni, teruji
  types/         database.ts (generate) · sorogan.ts
docs/            21 dokumen proyek + peran agen
test/            35 tes (27 domain + 8 navigasi/kerangka)
db/              migrasi 001 002 004 005 006 008 009 012 013 015 · check 003 010 014 016
tools/           buat_seed.py (seed dari .docx asatidz) · ukur-layout.mjs (ukur luberan responsif)
arsip/           versi vanilla satu-file sebelum Nuxt (masih berfungsi)
```

Kelima migrasi sudah ter-apply ke project `unozvswlxqbhqzmlsirl`.

---

## Data seed

Semuanya dari dua dokumen leger asli:

| | Jumlah |
|---|---|
| Ibarat / potongan tarkib | 60 |
| Soal BK 2 | 60 — 15 tiap tipe (ismiyah, fi'liyah, nawasikh, tabi') |
| Anak-tangga pertanyaan | 41 — lafad 9, ismiyah 9, fi'liyah 8, nawasikh 7, tabi' 8 |
| Santri | 20 |
| Kelompok | 4 × 5 santri |
| Ustadz | 4 |

**Skrip seed tidak pernah membangkitkan rahasia.** Ia idempoten dan sering
dijalankan ulang; nilai apa pun yang harus tetap sama antara repo dan dunia nyata
tidak boleh lahir dari perintah semacam itu. Ini pernah terjadi dengan kode klaim
ustadz — file seed diam-diam berbeda dari database tanpa gejala sampai ada yang
gagal login. Kode klaimnya kini dihapus ([db/015](db/015_hubungkan_ustadz_tanpa_kode.sql)),
aturannya tetap.

**Teks Arabnya tidak diketik ulang.** `tools/buat_seed.py` membacanya langsung
dari `.docx` — satu harakat meleset berarti soal yang berbeda. Dokumen memuat
bank soal dua kali; skrip membandingkan keduanya dan berhenti kalau ada satu
huruf pun yang berbeda. Saat dijalankan, keduanya identik.

```bash
python tools/buat_seed.py "path/ke/Tes Lisan BK 2.docx"
```

60 ibarat itu dipakai **dua kali**: sebagai soal BK 2, sekaligus bahan
ketuk-kata BK 1. Satu korpus, dua tingkat — dan tidak ada teks kitab yang
dikarang sendiri.

---

## Aturan nilai

`benar` = 1 · `dibantu` = 0.5 · `salah` = 0 · dilewati = tidak dihitung

**Nilai soal** = rata-rata langkah yang tercatat pada soal itu.
**Nilai santri** = rata-rata *nilai soal*, **bukan** rata-rata seluruh langkah.

Urutan ini bukan detail. Tangga tiap tipe beda panjang (9/9/8/7/8). Kalau
dirata-ratakan datar, soal bertangga panjang otomatis berbobot lebih besar —
dan hasilnya tetap terlihat wajar di layar.

Rumusnya hidup di **dua tempat**: TypeScript (nilai berjalan saat offline) dan
view Postgres (laporan). Duplikasi itu disengaja, tapi berarti keduanya bisa
menyimpang diam-diam — jadi keduanya dipaku ke skenario yang sama persis:

```bash
npm test                     # 27 tes; nilai benar 75.0 vs rumus datar 67.9
psql < db/003_check.sql      # sisi SQL: angka yang sama, lalu rollback
psql < db/016_check_hubungkan.sql # penghubungan identitas, lewat RPC sungguhan
psql < db/010_check_kalibrasi.sql   # kalibrasi berpasangan di bawah model kelompok
```

> **Setiap RPC wajib diuji lewat panggilan sungguhan, bukan disetel manual.**
> Badan plpgsql diresolusi PER NAMA SAAT DIJALANKAN, jadi migrasi bisa sukses
> total sementara fungsinya sudah mati. Itu persis yang terjadi: migrasi 004
> memindahkan `my_ustadz_id()` ke schema `priv`, policy ikut pindah sendiri
> (menyimpan OID), tapi badan `klaim_ustadz` tetap menunjuk nama lama — dan
> baru meledak saat ustadz pertama menghubungkan akunnya. Uji saat itu
> menyetel `ustadz.auth_id` lewat UPDATE langsung, jadi menguji *sekeliling*
> jalur itu. Diperbaiki di migrasi 006; `007_check_klaim.sql` menutup celahnya.

Test-nya juga gagal kalau kedua rumus suatu saat kebetulan menghasilkan angka
sama — karena saat itu ia kehilangan daya bedanya.

Nilai **tidak pernah disimpan**, selalu dihitung di view. Kalau bobotnya
diubah, seluruh sejarah ikut terkoreksi.

---

## Perintah

```bash
npm run dev          # server pengembangan
npm test             # 35 tes (vitest)
npm run typecheck    # vue-tsc, strict
npm run cek:layout   # ukur luberan + ganti shell di 320 s/d 1920px
npm run generate     # keluaran statis untuk hosting
```

Perbarui tipe setelah mengubah migrasi:

```bash
npx supabase gen types typescript --project-id unozvswlxqbhqzmlsirl > shared/types/database.ts
```

> `typescript` dipatok ke `~5.9`. TypeScript 7 (port native) belum didukung
> `vue-tsc` 3.3 — `nuxt typecheck` langsung mati. Jangan dinaikkan sebelum
> `vue-tsc` mendukungnya.

---

## Keamanan

- **RLS aktif di semua tabel.** Akun yang sudah login tapi belum klaim kode
  melihat **0 santri, 0 soal, 0 kode** — diuji langsung. Setelah klaim: 20 santri.
- Penghubungan identitas lewat `hubungkan_ustadz()`, yang menolak nama yang
  sudah dipakai akun lain. **Pendaftaran Supabase wajib tertutup** — itu pintu
  utamanya.
- Helper policy (`is_ustadz`, `my_ustadz_id`) ada di schema `priv` yang tidak
  diekspos PostgREST.
- Semua ustadz bisa **melihat** sesi satu sama lain (kalibrasi butuh itu),
  tapi hanya pemilik yang bisa **mengubah** sesinya.
- Middleware `ustadz.ts` hanya kenyamanan navigasi. Penjaga sebenarnya RLS —
  middleware yang dilewati tidak membocorkan data.

**Tiga peringatan advisor Supabase yang tersisa, semuanya disengaja:**

| Peringatan | Alasan |
|---|---|
| `hubungkan_ustadz` bisa dipanggil user login | Memang tugasnya; hanya menyentuh baris yang belum terpakai. |
| `putuskan_kenaikan` bisa dipanggil user login | Memang tugasnya; RLS + penjaga di dalamnya. |
| `rls_auto_enable` ×2 | **Bukan buatan sistem ini** — sudah ada di project. Event trigger yang menyalakan RLS otomatis pada tabel baru. Guardrail bagus, dibiarkan. Bertipe `event_trigger`, jadi tidak benar-benar bisa dipanggil lewat REST. |

---

## Sudah diuji / belum

**Sudah, langsung:** skema, RLS (akun belum klaim buta total), rumus nilai di
SQL dan TypeScript, RPC termasuk perilaku kirim ulang, 35 tes,
`vue-tsc` strict bersih, build produksi + PWA (32 entri precache), routing dan
middleware di browser, bilah antrean, serta tata letak layar penilaian pada
375 px — semua target sentuh ≥ 44 px dengan celah 7 px antar kata.

**Belum:** satu putaran penuh dengan akun sungguhan. Saya tidak membuat akun
atau memasukkan kata sandi. Alur daftar → klaim → nilai → cetak dari sisi
browser belum dijalankan. **Lakukan sekali dengan satu santri sebelum dipakai
ujian betulan.**

**Asumsi yang perlu dikonfirmasi:** 8 soal untuk BK 2 (2 × 4 tipe). BK 1 jelas
10 lafad dari 10 kolom leger; dokumen BK 2 hanya berisi banknya. Ubah
`PER_TIPE_BK2` di `shared/types/sorogan.ts` kalau praktiknya berbeda.

**Belum ada:** ekspor CSV (yang ada cetak leger), layar wali santri, aplikasi
santri, rekam audio. Semuanya ada di tabel penundaan [PLAN.md](PLAN.md) §9
lengkap dengan pemicu kapan ditambah.

---

## Langkah berikutnya

Yang menentukan bukan kodenya, tapi apakah penilaian pertama terasa **lebih
cepat** daripada menulis tangan. Uji satu ustadz, satu santri, 10 lafad, pakai
stopwatch. Kalau lebih lambat: perbaiki alurnya, jangan tambah fitur.
Ukuran keberhasilan tiap fase ada di [PLAN.md](PLAN.md) §11.
