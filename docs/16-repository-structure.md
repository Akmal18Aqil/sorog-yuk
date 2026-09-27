# 16 — Struktur Repo

```
.
├── app/                         Kode aplikasi (srcDir Nuxt 4)
│   ├── app.vue                  Kerangka: NuxtPage + BilahAntrean
│   ├── assets/css/main.css      Token warna, tipografi, kelas .arab, gaya cetak
│   ├── components/
│   │   ├── KetukKata.vue        BK1: ketuk kata pada ibarat → jadi soal
│   │   ├── TanggaPertanyaan.vue Tangga + tombol verdict + titik kemajuan
│   │   ├── SantriBaris.vue      Satu baris santri di daftar kelompok
│   │   ├── KesiapanRingkas.vue  Kepala kartu kesiapan naik + dua nilai tes
│   │   └── BilahAntrean.vue     Bilah "belum terkirim" / "macet"
│   ├── composables/
│   │   ├── useUstadz.ts         Identitas + pilih nama + keluar
│   │   ├── useAcuan.ts          Data acuan + cache localStorage
│   │   └── useSesi.ts           Orkestrasi sesi penilaian
│   ├── middleware/ustadz.ts     Hanya akun terhubung yang lewat
│   ├── pages/
│   │   ├── index.vue            Masuk / daftar / pilih nama ustadz
│   │   ├── mulai.vue            Pilih kelompok, tingkat, keperluan, santri
│   │   ├── nilai.vue            Layar penilaian
│   │   ├── hasil.vue            Diagnostik + leger cetak
│   │   └── kenaikan.vue         Kesiapan naik + catat nilai luring + putusan
│   ├── plugins/antrean.client.ts Satu antrean untuk seluruh aplikasi
│   └── utils/
│       ├── repo.ts              SATU-SATUNYA titik sentuh Supabase
│       ├── antrean.ts           Antrean kirim offline
│       └── tanggal.ts           hariIni() waktu setempat
│
├── shared/                      Dipakai bersama; alias #shared
│   ├── domain/                  MURNI — tanpa Vue/Supabase/I/O
│   │   ├── nilai.ts             bobot, nilaiSoal, nilaiSesi, nilaiDatarKeliru
│   │   ├── tangga.ts            Mesin keadaan tangga (immutable)
│   │   ├── pembagian.ts         Pembagian merata BK2 per tipe
│   │   └── ringkasan.ts         Penggabungan diagnostik (ditimbang)
│   └── types/
│       ├── database.ts          DIBANGKITKAN dari skema — jangan diedit tangan
│       └── sorogan.ts           Union domain + entitas + konstanta
│
├── test/                        27 tes domain (vitest)
│   ├── nilai.test.ts            Dipaku ke angka yang sama dengan db/003
│   ├── tangga.test.ts
│   ├── pembagian.test.ts
│   └── ringkasan.test.ts
│
├── db/
│   ├── 001_schema.sql           Tabel, view, fungsi, seluruh policy RLS
│   ├── 002_seed.sql             DIBANGKITKAN oleh tools/buat_seed.py
│   ├── 003_check.sql            CHECK: urutan rata-rata nilai
│   ├── 004_helper_ke_schema_privat.sql
│   ├── 005_rpc_simpan_penilaian.sql
│   ├── 006_perbaiki_acuan_klaim_ustadz.sql
│   ├── 008_kelompok.sql         Kelompok + kalibrasi berpasangan
│   ├── 009_seed_kelompok.sql
│   ├── 010_check_kalibrasi.sql  CHECK: pembalikan tanda kalibrasi
│   ├── 012_kelas_master_data.sql
│   ├── 013_tes_offline_dan_kenaikan.sql
│   ├── 014_check_kenaikan.sql   CHECK: gerbang kenaikan + lintas kelas
│   ├── 015_hubungkan_ustadz_tanpa_kode.sql
│   └── 016_check_hubungkan.sql  CHECK: penghubungan identitas + RLS buta total
│
├── tools/buat_seed.py           Bangkitkan seed dari .docx asatidz (stdlib saja)
├── docs/                        Dokumen ini
├── arsip/                       Versi vanilla satu-file sebelum Nuxt
├── public/icon.svg              Ikon PWA
├── nuxt.config.ts · tsconfig.json · package.json · .gitignore
├── PLAN.md                      Rencana produk & peta jangka panjang
└── README.md                    Cara pakai & jalankan
```

## Di mana menaruh sesuatu

| Menambahkan | Tempatnya |
|---|---|
| Aturan yang bisa dijelaskan tanpa menyebut layar | `shared/domain/` |
| Nilai enum baru yang dipakai di banyak tempat | `shared/types/sorogan.ts` |
| Query Supabase | `app/utils/repo.ts` — **tidak di tempat lain** |
| Keadaan yang dipakai lebih dari satu halaman | `app/composables/` dengan `useState` |
| Efek samping global (pendengar, timer) | `app/plugins/*.client.ts` |
| Perubahan skema | Migrasi **baru** di `db/`, bernomor berikutnya |
| Verifikasi SQL | `db/NNN_check_*.sql`, aman diulang, rollback sendiri |
| Alasan lokal sebuah keputusan | Komentar di berkas itu sendiri |
| Aturan yang mengikat semua orang | `docs/00-project-rules.md` |

## Penamaan

- Berkas dan identifier: **bahasa Indonesia** (`nilaiSoal`, `susunTangga`,
  `bagikanBK2`, `tes_offline`). Domainnya berbahasa Indonesia; menerjemahkannya
  ke Inggris membuat kode menjauh dari lembar asatidz.
- Kolom database: `snake_case`, tidak diubah ke camelCase di TypeScript.
  Penggantian nama itu kosmetik dan hanya menambah lapisan yang bisa salah.
- Berkas check: berakhiran `_check` atau berawalan `check_` — **bukan migrasi**.
- Komponen Vue: `PascalCase`.

## Berkas yang tidak boleh diedit tangan

| Berkas | Cara memperbaruinya |
|---|---|
| `shared/types/database.ts` | `npx supabase gen types typescript --project-id <ref>` |
| `db/002_seed.sql` | `python tools/buat_seed.py "<path .docx>"` |
| `db/00*.sql` yang sudah ter-apply | Jangan. Buat migrasi baru. |
