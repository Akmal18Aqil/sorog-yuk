# 07 — Frontend Agent

Halaman, komponen, composable. Tidak memiliki aturan bisnis.

## Yang dimiliki

```
app/pages/        index · mulai · nilai · hasil · kenaikan
app/components/   KetukKata · TanggaPertanyaan · SantriBaris · BilahAntrean
app/composables/  useUstadz · useAcuan · useSesi
app/middleware/   ustadz.ts
app/assets/css/   main.css
```

## Hukum pertama: lebih cepat dari kertas

Setiap perubahan pada alur penilaian dinilai dari **jumlah ketukan**, bukan
kelengkapan fitur. Kalau menilai lewat aplikasi lebih lambat daripada menulis
tangan, asatidz kembali ke kertas dan proyek ini mati (R12).

Konsekuensi konkret:

- **Nol pengetikan Arab.** Lafad dipilih dengan mengetuk kata pada ibarat.
- Layar **maju sendiri** setelah verdict diketuk. Tidak ada tombol "berikutnya".
- Tipe tangga tidak pernah dipilih manual — ia melekat pada soal.
- Pembagian soal BK2 otomatis; penguji tidak memilih apa pun.

## Aturan sentuh dan tata letak

- Target sentuh minimum **44 × 44 px**. Tombol verdict 78 px.
- **Celah antar target tidak boleh nol.** Vue membuang whitespace antar elemen
  `v-for`; kotak sentuh dua kata Arab bisa menempel dan ketukan di perbatasan
  mencatat lafad yang salah. Pakai `{{ ' ' }}` eksplisit di dalam
  `<template v-for>`. Diukur: celah 7 px.
- Kata Arab pendek (`دَم`) hanya ~27 px → beri `min-width: 44px`.
- Nama panjang mengalah dengan ellipsis; keterangan `flex-shrink: 0` supaya tidak
  terdorong keluar layar.
- Uji di **375 px**. `document.body.scrollWidth` tidak boleh melebihi `innerWidth`.
- Teks Arab: `direction: rtl` dan kelas `.arab`. Harakat wajib tampil utuh.

## Aturan reaktivitas

- **`reactive`, bukan objek biasa, untuk yang dipakai di template.** Ref di dalam
  objek biasa **tidak** dibuka otomatis di template, sehingga
  `$antrean.jumlah > 0` membandingkan objek ref dengan angka dan selalu bernilai
  true. Bug ini nyata dan hanya tertangkap `vue-tsc`.
- `print()` telanjang di template diresolusi ke instance komponen, bukan
  `window`. Bungkus: `const cetak = () => window.print()`.
- **Jangan membaca `useSupabaseUser()` untuk keputusan yang diambil tepat
  setelah panggilan auth.** Ref itu diisi lewat `onAuthStateChange` dan belum
  terisi saat `signInWithPassword()` baru selesai — maupun pada muat pertama
  halaman. Akibatnya nyata: ustadz yang sudah terhubung dilempar ke layar pilih
  nama, lalu server menolak karena memang sudah terhubung. Untuk keputusan,
  baca `sb.auth.getSession()` (lokal, tanpa round-trip). Ref-nya hanya untuk
  tampilan yang boleh menyusul.
- Efek samping global (pendengar `online`, timer) dipasang di **plugin**, bukan
  composable. Kalau tiap komponen memasangnya sendiri, satu penilaian bisa
  terkirim berkali-kali bersamaan.

## Aturan composable

- Tanpa aturan bisnis. Semua aturan diimpor dari `shared/domain/`.
- `useState` untuk keadaan bersama; `ref` untuk keadaan lokal halaman.
- Cache data acuan boleh; cache nilai tidak pernah (R6).
- Kalau memuat data acuan gagal tapi cache lama ada, sesi **tetap jalan**. Hanya
  kalau belum pernah memuat sama sekali, beri tahu bahwa pemakaian pertama butuh
  sinyal.

## Aturan degradasi offline

- Penilaian tidak pernah menunggu jaringan.
- Halaman laporan butuh sinyal → tampilkan pesan jujur, bukan angka kosong yang
  tampak seperti nol.
- Tampilkan jumlah antrean dan jumlah macet. Jangan pernah menyembunyikan
  kegagalan kirim.

## Aturan bahasa antarmuka

Bahasa Indonesia, istilah pesantren dipakai apa adanya (santri, ustadz, lafad,
tarkib, i'rob, ibarat, sorogan). Jangan diterjemahkan atau di-Inggris-kan.

Verdict ditampilkan dengan keterangannya: **Benar** (lancar sendiri) ·
**Dibantu** (ditunjuki dulu) · **Salah** (belum bisa). Tanpa keterangan itu,
"dibantu" akan ditafsirkan berbeda oleh tiap penguji dan datanya jadi tidak
sebanding.

## Checklist sebelum menyerahkan

- [ ] `npm run typecheck` hijau
- [ ] Diverifikasi di browser: tanpa error konsol
- [ ] **Diukur** pada 375 px: target ≥ 44 px, ada celah, tanpa luberan horizontal
- [ ] Tidak ada aturan bisnis yang merembes ke komponen/composable
- [ ] Alur penilaian tidak bertambah ketukan
- [ ] Halaman baru pakai `definePageMeta({ middleware: 'ustadz' })`
