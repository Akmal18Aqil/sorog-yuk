# 17 — Standar Penulisan Kode

## Prinsip: kode paling sedikit yang bekerja

Sebelum menulis, berhenti di anak-tangga pertama yang menahan: perlu ada sama
sekali? sudah ada di repo? sudah dilakukan Postgres/stdlib? ada fitur bawaan
platform? ada dependensi terpasang? bisa satu baris? — baru kemudian tulis.

Yang dilarang tanpa permintaan eksplisit: interface dengan satu implementasi,
factory untuk satu produk, konfigurasi untuk nilai yang tidak pernah berubah,
scaffolding "untuk nanti", state manager untuk 4 halaman.

Penghapusan lebih baik daripada penambahan. Membosankan lebih baik daripada
pintar — yang pintar adalah yang harus dibaca orang jam 3 pagi.

## Bahasa dan penamaan

- Identifier **bahasa Indonesia**: `nilaiSoal`, `susunTangga`, `bagikanBK2`,
  `tandaiSelesai`. Domainnya berbahasa Indonesia; meng-Inggris-kannya membuat
  kode menjauh dari lembar asatidz.
- Kolom database `snake_case`, dipakai apa adanya di TypeScript.
- Boolean diberi nama pernyataan: `siap`, `lolos_online`, `memenuhi_ambang`.

## TypeScript

- `strict: true`. `any` hanya dengan alasan tertulis di komentar.
- Persempit `string` dari database jadi union di batas repo, jangan dibiarkan
  menyebar. `text` + CHECK di Postgres muncul sebagai `string` di TypeScript, dan
  `string` membiarkan salah ketik lolos sampai runtime.
- Union dari konstanta, bukan enum:
  ```ts
  export const VERDICT = ['benar', 'dibantu', 'salah'] as const
  export type Verdict = (typeof VERDICT)[number]
  ```
  Satu sumber untuk tipe **dan** untuk iterasi di template.
- `readonly` untuk parameter yang tidak dimutasi. Mesin keadaan tangga immutable.
- Tipe turunan lebih baik daripada tipe ditulis dua kali:
  `export type Antrean = ReturnType<typeof buatAntrean>`.

## Vue

- `<script setup lang="ts">`, selalu.
- `defineProps` dan `defineEmits` bertipe generik, bukan objek runtime.
- **`reactive` untuk objek yang dipakai di template.** Ref di dalam objek biasa
  tidak dibuka otomatis di template — `obj.jumlah > 0` akan membandingkan ref
  dengan angka dan selalu true.
- Jangan panggil global telanjang di template (`print()`). Bungkus di script:
  `const cetak = () => window.print()`.
- Whitespace antar elemen `v-for` dibuang Vue. Kalau celah visual/sentuh penting,
  tulis eksplisit `{{ ' ' }}` di dalam `<template v-for>`.
- `<style scoped>` untuk gaya komponen; hanya token dan kelas lintas-komponen
  yang boleh di `main.css`.
- Komponen tidak mengakses data. Semua data lewat props.

## SQL

- Komentar menjelaskan **kenapa**, bukan apa. Kalau ada jebakan, tulis
  jebakannya.
- Semua fungsi: `set search_path = ''`, semua acuan berkualifikasi penuh.
- Acuan di dalam `plpgsql` wajib benar — badan plpgsql diikat **per nama saat
  dijalankan**, sehingga migrasi bisa sukses sementara fungsinya sudah mati.
- View: `with (security_invoker = on)`.
- Tabel baru: `enable row level security` + policy, di migrasi yang sama.
- Pesan error ditulis untuk **ustadz**, bukan pengembang.
- Migrasi bernomor, tidak pernah diedit setelah ter-apply.

## Komentar

Tulis komentar hanya untuk yang tidak bisa dibaca dari kodenya:

- **Kenapa** sebuah pilihan diambil, terutama yang tampak aneh.
- Jebakan yang pernah memakan korban.
- Batas atas sebuah penyederhanaan, ditandai `ponytail:` beserta jalur
  peningkatannya:
  ```sql
  -- ponytail: subquery skalar per grup. Aman utk puluhan penguji;
  -- ganti ke CTE kalau sudah ratusan.
  ```

Jangan tulis komentar yang mengulang kodenya. Kalau penjelasan lebih panjang
daripada kodenya, hapus penjelasannya — kecuali itu memang jebakan yang perlu
diwariskan.

## Penanganan error

- Validasi di trust boundary: batas repo dan RPC.
- Gagal keras kalau skema dan aplikasi tidak sinkron — jangan pura-pura jalan.
- Jangan pernah menelan error tanpa jejak yang bisa dilihat pengguna.
- Kegagalan kirim **tidak boleh** menghapus data. Antrean menahan, memindahkan
  ke daftar macet, dan menampilkan jumlahnya.
- `localStorage` yang rusak dibuang, bukan membuat aplikasi tak bisa dibuka —
  ustadz sedang di tengah ujian.

## Yang tidak pernah disederhanakan

Validasi di trust boundary · penanganan error yang mencegah kehilangan data ·
keamanan · aksesibilitas dasar (target sentuh, kontras, label) · apa pun yang
diminta eksplisit.

Logika non-sepele tanpa satu check yang bisa dijalankan = belum selesai.
