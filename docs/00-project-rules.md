# 00 — Aturan Proyek

Aturan yang tidak boleh dilanggar siapa pun — manusia maupun agen. Kalau sebuah
perubahan bertabrakan dengan dokumen ini, yang salah perubahannya.

---

## R1. Verdict per langkah adalah unit atom. Nilai tidak pernah disimpan.

Yang ditulis ke database adalah `(penilaian, langkah, verdict)`. Nilai selalu
**diturunkan** di view. Jangan pernah menambah kolom `nilai` pada tabel.

**Kenapa:** kalau bobot berubah, seluruh sejarah harus ikut terkoreksi. Nilai
tersimpan mengunci rumus selamanya dan membuat data lama tak sebanding dengan
data baru.

## R2. Nilai dirata-ratakan PER SOAL dulu, baru antar soal.

Tangga tiap tipe beda panjang (lafad 9, ismiyah 9, fi'liyah 8, nawasikh 7,
tabi' 8). Merata-ratakan seluruh langkah secara datar memberi bobot lebih besar
pada soal bertangga panjang.

**Kenapa keras:** hasilnya tetap terlihat wajar di layar. Hanya test yang bisa
menangkapnya. Rumus benar menghasilkan 75.0; rumus datar 67.9.

Dipagari `test/nilai.test.ts` dan `db/003_check.sql`. Keduanya wajib sepakat.

## R3. Langkah yang dilewati TIDAK menghasilkan baris.

"Tidak berlaku" bukan nilai nol. Langkah bersyarat (BK1 no. 6–7 hanya isim,
no. 9 hanya isim mabni) yang tidak relevan tidak punya baris `jawaban` sama
sekali. Itu sebabnya rata-rata otomatis adil tanpa filter khusus di mana pun.

## R4. Rubrik ditentukan TIPE soal, bukan per soal.

Satu tangga dipakai belasan soal. Menyimpan rubrik per soal berarti duplikasi
dan revisi rubrik jadi migrasi massal.

## R5. Setiap RPC diuji lewat panggilan sungguhan.

Jangan pernah menguji "sekeliling" sebuah RPC dengan menyetel tabel langsung.

**Kenapa:** badan `plpgsql` diresolusi **per nama saat dijalankan**. Migrasi bisa
sukses total sementara fungsinya sudah mati. Itu benar-benar terjadi: migrasi
`004` memindahkan `my_ustadz_id()` ke schema `priv`, policy ikut pindah sendiri
(menyimpan OID), tapi badan `klaim_ustadz` tetap menunjuk nama lama — dan baru
meledak di tangan ustadz pertama. Uji saat itu menyetel `ustadz.auth_id` lewat
UPDATE. Lihat `db/006`, `db/016`.

## R6. Panggilan Supabase tidak pernah di-cache.

Data acuan (santri, soal, tangga, ibarat, kelompok) boleh di-cache; **nilai
tidak pernah**. Nilai basi yang tampil seolah baru jauh lebih berbahaya daripada
pesan gagal yang jujur.

## R7. Penilaian tidak pernah menunggu jaringan.

Hasil ketukan masuk `localStorage` seketika, dikirim belakangan. Sinyal di kelas
pesantren tidak bisa diandalkan. RPC penyimpanan wajib **aman diulang**.

## R8. Rahasia tidak lahir dari perintah yang diulang-ulang.

Ini pernah terjadi: `tools/buat_seed.py` sempat mengacak kode klaim ustadz tiap
dijalankan. Karena skripnya idempoten dan sering dijalankan ulang, file seed
diam-diam berbeda dari kode yang sudah beredar — tanpa gejala apa pun sampai ada
yang gagal login.

Kode klaim itu sendiri sudah dihapus (`db/015`), tapi aturannya tetap: kalau
sebuah nilai harus tetap sama antara repo dan dunia nyata, ia tidak boleh
dibangkitkan oleh perintah yang dijalankan berulang.

## R9. Data santri adalah data anak di bawah umur. Batas keras.

- RLS aktif di semua tabel. Akun yang login tapi belum terhubung ke baris
  `ustadz` melihat **nol baris apa pun**.
- **Pendaftaran di Supabase wajib tertutup** setelah semua ustadz terdaftar.
  Sejak kode klaim dihapus, itulah pintu yang menjaga.
- Nama santri tidak pernah muncul di halaman publik, demo, screenshot, atau
  artefak yang dibagikan.
- Middleware hanya kenyamanan navigasi. Penjaga sebenarnya RLS.

## R10. AI tidak menilai bacaan kitab.

Alasannya kultural, bukan teknis: i'rob punya otoritas dan sanad. Peran AI hanya
(a) menyusun draf kunci jawaban untuk diverifikasi ustadz, dan (b) memilih soal
berikutnya. **AI menyiapkan, ustadz memutuskan.** Jangan pernah dibalik.

## R11. Sistem mengusulkan kenaikan; asatidz memutuskan.

Kenaikan kelas tidak pernah otomatis. Menaikkan di luar ambang **boleh** —
kebijaksanaan asatidz nyata — tapi alasannya wajib tercatat. Keputusan di luar
aturan tanpa keterangan tidak bisa ditinjau ulang, dan justru itu yang paling
perlu bisa ditinjau.

## R12. Lebih cepat dari kertas, atau proyek ini mati.

Kalau menilai lewat aplikasi lebih lambat daripada menulis tangan, asatidz akan
kembali ke kertas. Setiap perubahan UI pada alur penilaian dinilai dari jumlah
ketukan, bukan dari kelengkapan fitur. Nol pengetikan Arab.

## R13. Ambang sentuh 44 px, dan celah antar target tidak boleh nol.

Kata Arab pendek seperti `دَم` hanya selebar ~27 px. Salah ketuk = soal yang
salah tercatat. Vue membuang whitespace antar elemen `v-for`, jadi kotak sentuh
bisa menempel tanpa celah — ukur di browser, jangan diasumsikan.

## R14. Domain murni. Tanpa Vue, tanpa Supabase, tanpa I/O.

`shared/domain/` tidak boleh mengimpor apa pun dari `app/` atau dari Supabase.
Aturan ilmu alat bukan detail tampilan.

## R15. Kualitas dinyatakan lolos hanya jika ketiganya hijau.

```bash
npm test            # 27 tes domain
npm run typecheck   # vue-tsc strict
npm run build       # produksi + PWA
```

Ditambah check SQL yang relevan (`db/003`, `007`, `010`, `014`).
Tidak ada "sebagian lolos".

## R16. Jangan naikkan `typescript` di atas `~5.9`.

TypeScript 7 (port native) belum didukung `vue-tsc` 3.3; `nuxt typecheck`
langsung mati. Naikkan hanya setelah `vue-tsc` mendukungnya.

## R17. Laporkan apa adanya.

Kalau test gagal, katakan gagal beserta keluarannya. Kalau sebuah langkah
dilewati, katakan dilewati. Jangan pernah menyatakan "sudah diuji" untuk jalur
yang sebenarnya diuji dari samping.
