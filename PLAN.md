# Sorogan Digital — Rencana

Dari: `Tes Lisan BK 1.docx` (leger lafad, tangga 9 pertanyaan) dan
`Tes Lisan BK 2.docx` (bank 60 soal tarkib, 4 tipe tangga).

---

## 1. Masalah sebenarnya

Bukan "belum ada aplikasi". Masalahnya tiga, dan semuanya kelihatan dari kertas:

1. **Kertas cuma muat hasil, bukan proses.** 10 kolom per santri = 10 angka.
   Padahal penguji menanyakan 6–9 anak-tangga per lafad. 90% informasi dibuang
   di detik ia ditulis.
2. **Tidak ada memori.** Ujian selesai, leger masuk map. Semester depan penguji
   mulai dari nol, tidak tahu Satria dulu lemah di mana.
3. **Penguji tidak terkalibrasi.** 4 ustadz × 5 santri, tiap santri dinilai satu
   orang saja. Kalau Ust. A lebih longgar dari Ust. B, tidak ada yang tahu, dan
   nilai santri jadi undian penguji.

Nomor 3 ini yang paling mahal secara keadilan, dan paling tak terlihat di kertas.

## 2. Insight kunci

**Unit atom sistem = `(lafad, langkah_tangga, verdict)`, bukan `(santri, nilai)`.**

Simpan itu, dan semua fitur "canggih" nanti muncul sendiri tanpa kode tambahan:
diagnostik per santri, peta kelemahan kelas, kalibrasi penguji, kurikulum
berbasis data. Salah di sini = seluruh grand plan harus dibongkar ulang.
Benar di sini = fase-fase berikutnya cuma ganti UI.

Tambahan gratis yang tidak ada di kertas:
- **Verdict 3 nilai**, bukan benar/salah: `benar` / `dibantu` / `salah`.
  "Dibantu/ditunjuki dulu baru bisa" adalah realitas sorogan dan sinyal
  paling informatif untuk mengukur kemajuan.
- **Langkah yang tidak berlaku tidak dicatat.** Tangga BK1 langkah 6–7
  (ma'rifat/nakiroh) hanya untuk isim; langkah 9 khusus isim mabni.
  Jangan dipaksa jadi nilai 0 — cukup tidak direkam.
- **Waktu jawab.** Timestamp tiap ketukan. Gratis, dan membedakan santri yang
  hafal-lancar dari yang mikir-lama walau sama-sama benar.

## 3. Grand plan (arah, bukan jadwal)

| Lapis | Isi | Yang dibuka |
|---|---|---|
| **L1 — Leger Digital** | Ganti kertas ujian lisan | Data proses, diagnostik |
| **L2 — Sorogan Harian** | Sorogan tiap hari ikut tercatat | Rekam jejak longitudinal, rapor wali |
| **L3 — Sorogan Async** | Santri rekam bacaan + i'rob, ustadz menilai belakangan | **Rasio ustadz:santri dari 1:5 → 1:50** |
| **L4 — Platform** | Multi-pesantren, bank kitab bersama, sanad digital | Skala keluar pesantren |

Nilai ekonomi platform ada di **L3**. Sorogan macet karena jam ustadz, bukan
karena kurang aplikasi. Async memecah leher botol itu — itulah produknya.
L1 dan L2 adalah cara mendapatkan data dan kepercayaan untuk sampai ke L3.

---

## 4. Jangka pendek — 6 minggu, 3 fase

### Fase 0 — "Leger Digital" (3 hari kerja)

**Satu file HTML. Tanpa backend, tanpa build, tanpa akun, tanpa internet.**
Dibuka dari browser HP penguji, data di `localStorage`, ekspor CSV/JSON.

Alasan lazy: untuk 20 santri × 4 penguji, backend adalah beban tanpa imbalan.
Yang dibutuhkan sekarang cuma membuktikan alurnya dipakai orang.

Alur penguji (target: **lebih cepat dari menulis tangan**, kalau tidak, mereka
balik ke kertas dan proyek mati):

1. Pilih nama sendiri → pilih santri (daftar sudah di-seed dari leger).
2. **Layar menampilkan ibarat kitab utuh. Penguji mengetuk satu kata.**
   Kata itu jadi lafad soal. **Nol pengetikan Arab.**
   (BK2: cukup pilih nomor soal 1–60, banknya sudah pasti.)
3. Tangga muncul otomatis sesuai tipe soal. Tiap langkah: 3 tombol besar
   ✓ / ~ / ✗. Ketuk → langsung turun ke langkah berikutnya.
   Langkah tidak relevan → tombol "lewati".
4. Selesai 10 lafad → otomatis pindah santri.

Output:
- **Cetakan yang bentuknya persis leger kertas.** Ini jembatan adopsi:
  kyai/kepala madrasah menerima lembar yang sama seperti biasa, cuma sudah
  terisi. Nol pelatihan di sisi pembaca.
- Halaman diagnostik (bagian 7).
- File JSON = cikal bakal isi database Fase 2.

Pertanyaan "opsional/cukup sekali" di BK2 (*"apa pengertian mubtada'?"*)
ditandai `sekali_per_sesi` — muncul di soal pertama saja, tidak diulang 15 kali.

### Fase 1 — Pakai di ujian betulan (2 minggu)

Jalankan satu siklus ujian nyata dengan 4 penguji. Yang diukur, bukan yang
dirasa:

- Detik per santri, aplikasi vs kertas. **Kalau lebih lambat, perbaiki dulu
  sebelum menambah apa pun.**
- Berapa penguji yang diam-diam kembali ke kertas.
- Langkah tangga mana yang paling sering "dilewati" — tanda rubriknya perlu
  diperbaiki, bukan santrinya.
- Sebar hasil kalibrasi penguji ke musyawarah asatidz. Ini momen sistem
  membuktikan diri: ia menunjukkan sesuatu yang kertas tidak pernah bisa.

Jangan tambah fitur apa pun di fase ini.

### Fase 2 — "Sorogan Harian" + backend (3–4 minggu)

Ini pembalikan strategisnya: **ujian lisan cuma 2× setahun, sorogan tiap hari.**
Nilai sistem 100× lebih besar kalau dipakai harian.

Aplikasi yang sama, mode harian: ustadz buka → pilih santri → ketuk kata di
halaman yang sedang dibaca → tandai tangganya. 30 detik per santri.

Yang ditambah, hanya karena sekarang benar-benar perlu:
- **Supabase** (Postgres + Auth + Realtime). Data keluar dari HP satu orang.
- **Sinkronisasi offline-first**: antrean di IndexedDB, kirim saat ada sinyal.
  Wajib, bukan opsional — sinyal di kelas pesantren tidak bisa diandalkan.
- **Kartu santri**: kurva per anak-tangga sepanjang waktu. Satu layar, dibuka
  ustadz sebelum menyorog.
- Login: PIN 4 angka per ustadz. Cukup. Bukan data finansial.

---

## 5. Skema data (bagian yang tidak boleh salah)

```sql
-- Kitab & materi
create table kitab      (id bigserial primary key, nama text, pengarang text);
create table ibarat     (id bigserial primary key, kitab_id bigint references kitab,
                         halaman int, teks text, urutan int);
                        -- teks disimpan utuh; tokenisasi kata di sisi UI

-- Bank soal (60 soal BK2 masuk sini; lafad BK1 lahir dari ketukan di ibarat)
create table soal       (id bigserial primary key, ibarat_id bigint references ibarat,
                         teks text not null,            -- lafad atau potongan tarkib
                         tipe text not null,            -- lafad|ismiyah|filiyah|nawasikh|tabi
                         tingkat text,                  -- BK1|BK2
                         nomor_bank int);               -- 1..60, null kalau ad-hoc
                        -- tipe DISIMPAN, bukan dihitung dari nomor_bank.
                        -- Pembagian 15-15-15-15 itu fakta bank sekarang,
                        -- bukan aturan; sekali soal ditambah, rumusnya patah.

-- Rubrik: tangga pertanyaan. Ditentukan TIPE, bukan per-soal.
create table langkah    (id bigserial primary key,
                         tipe text not null, urutan int not null,
                         pertanyaan text not null,
                         bersyarat text,                -- mis. 'isim', 'marifat'
                         sekali_per_sesi bool default false,
                         unique (tipe, urutan));

-- Pelaksanaan
create table santri     (id bigserial primary key, nama text, kelas text,
                         tingkat text default 'BK1');   -- tingkat SEKARANG, untuk memilih bank
                        -- riwayat tingkat tidak perlu disimpan: sudah terbaca
                        -- dari soal.tingkat pada penilaian lampau

-- Satu ustadz memegang satu kelompok, dan kelompoknya berganti-ganti.
create table kelompok       (id bigserial primary key, nama text, urutan int);
create table kelompok_santri(kelompok_id bigint, santri_id bigint unique);
-- PENUGASAN ustadz->kelompok sengaja tidak punya tabel sendiri. Justru karena
-- berputar: kolom "penanggung jawab" akan basi terus dan menuntut admin
-- merawatnya. Penugasan direkam per sesi (`sesi.kelompok_id`), sehingga rotasi
-- tidak butuh perubahan data apa pun dan riwayatnya tetap utuh.
create table ustadz     (id bigserial primary key, nama text, pin text);
create table sesi       (id bigserial primary key, tanggal date, ustadz_id bigint,
                         mode text,                     -- ujian|harian
                         kelompok_id bigint);           -- kelompok yang dipegang hari itu
create table penilaian  (id bigserial primary key, sesi_id bigint references sesi,
                         santri_id bigint references santri,
                         soal_id bigint references soal, urutan int);

-- INTI SISTEM. Semua nilai & analitik diturunkan dari tabel ini.
create table jawaban    (id bigserial primary key,
                         penilaian_id bigint references penilaian,
                         langkah_id bigint references langkah,
                         verdict text not null,         -- benar|dibantu|salah
                         detik numeric,
                         catatan text,
                         unique (penilaian_id, langkah_id));
```

Tiga keputusan yang menahan seluruh bangunan:

1. **Rubrik ditentukan `tipe`, bukan disimpan per soal.** Dokumennya sendiri
   sudah begitu — satu tangga dipakai 15 soal. Menyimpan rubrik per soal =
   duplikasi 15×, dan revisi rubrik jadi migrasi massal.
2. **Nilai tidak disimpan.** Nilai = fungsi dari `jawaban`, dihitung di view.
   Kalau bobot berubah, seluruh sejarah ikut terkoreksi. Menyimpan nilai =
   mengunci rumus selamanya.
3. **Langkah tidak berlaku = baris tidak ada.** Bukan verdict "N/A". Rata-rata
   otomatis benar tanpa filter khusus di mana-mana.

**Rumus nilai (di view, bukan di aplikasi):**
`benar=1, dibantu=0.5, salah=0` → nilai lafad = rata-rata langkah yang tercatat
→ nilai santri = rata-rata 10 lafad × 100.

---

## 6. Dua tingkat: BK 1 dan BK 2

Sementara ini hanya ada dua tingkat, dan keduanya **berbeda bentuk**, bukan
sekadar berbeda tingkat kesulitan:

| | BK 1 | BK 2 |
|---|---|---|
| Objek | Satu **lafad** | Satu **tarkib** (potongan kalimat) |
| Asal soal | Ad-hoc, ditunjuk penguji dari ibarat | **Bank tetap 60 soal** |
| Jumlah tangga | 1 (`lafad`, 9 langkah) | 4 (ismiyah / fi'liyah / nawasikh / tabi') |
| Layar penguji | Ketuk kata di ibarat | Pilih nomor soal (tangga muncul sendiri) |

**Konsekuensi 1 — tidak ada sistem jenjang.** `tingkat` cukup kolom teks.
Pemetaan tingkat → tipe soal isinya lima baris dan tidak berubah. Tabel jenjang,
mesin kenaikan tingkat, atau kurikulum berjenjang: jangan dibuat sampai ada
tingkat ketiga yang benar-benar berbeda pola.

**Konsekuensi 2 — nol pemilihan tipe di BK 2.** Penguji cukup pilih nomor soal;
tangganya sudah melekat pada soal. Satu ketukan lebih sedikit, dan mustahil
salah pilih tangga.

**Konsekuensi 3 — pembagian soal BK 2 harus otomatis dan berimbang.**
Ini yang paling mudah luput. Empat tipe itu tidak sama beratnya: santri yang
kebagian 5 soal nawasikh dinilai jauh lebih keras daripada yang kebagian 5 soal
ismiyah — padahal nilainya diperlakukan setara. Di kertas ini tidak kelihatan.

> Aplikasi membagikan soal **merata per tipe**, diacak: 2 ismiyah, 2 fi'liyah,
> 2 nawasikh, 2 tabi' = 8 soal. Penguji tidak memilih apa pun.

Gratis, menghapus satu sumber ketidakadilan, sekaligus menjamin tiap santri
punya data di keempat tipe — tanpa itu, diagnostik per tipe berlubang.

**Konsekuensi 4 — panjang tangga berbeda (9/8/7/8 langkah), dan itu tidak apa-apa**
selama urutan hitungnya benar: nilai per soal = rata-rata **langkah yang tercatat
pada soal itu**, baru dirata-ratakan antar soal. Kalau langsung merata-ratakan
seluruh langkah dalam satu sesi, soal bertangga panjang otomatis berbobot lebih
besar — bug diam-diam yang tidak akan pernah ketahuan dari melihat hasilnya.

**Satu hal yang saya belum tahu:** berapa soal per santri di BK 2? BK 1 jelas 10
lafad (10 kolom di leger), tapi dokumen BK 2 hanya berisi banknya. Sementara
saya pakai **8 soal (2 per tipe)** karena itu angka terkecil yang masih memberi
data di keempat tipe. Tinggal ganti satu angka kalau praktiknya berbeda.

## 7. Tangga pertanyaan (seed `langkah`)

**`lafad` (BK1)** — 1 Kalimat apa? · 2 Tandanya apa? · 3 I'robnya apa? ·
4 Tanda i'robnya apa? · 5 Kenapa pakai tanda itu? · 6 Ma'rifat/nakiroh? *(isim)* ·
7 Ma'rifat yang mana? *(ma'rifat)* · 8 Penerapan lafad (mufrod/tatsniyah/jamak) ·
9 Isim mabni: dhomir/maushul/isyaroh? *(mabni)*

**`ismiyah` (1–15)** — Ismiyah/fi'liyah? · *Apa itu jumlah ismiyah?* ᵃ ·
Mubtada'nya mana? · *Pengertian mubtada'?* ᵃ · Termasuk mubtada' apa? ·
Khobarnya mana? · *Khobar itu apa?* ᵃ · Termasuk khobar apa? · Tambah amil nawasikh!

**`filiyah` (16–30)** — Ismiyah/fi'liyah? · *Apa itu jumlah fi'liyah?* ᵃ ·
Fa'il/naib fa'ilnya mana? · *Apa itu fa'il/naib fa'il?* ᵃ · Dhahir atau dhomir? ·
Fi'il mabni ma'lum/majhulnya mana? · Kenapa? · Ubah ke ma'lum/majhul!

**`nawasikh` (31–45)** — Ada nawasikh? · Mana amilnya? · Amalnya apa? ·
Mana isimnya? · Mana khobarnya? · Ganti dengan amil lain! · Buang amilnya!

**`tabi` (46–60)** — Ada tabi'? · Yang mana? · Termasuk tabi' apa? ·
Apa pengertiannya? · Termasuk macam yang mana? *(selain athaf)* · I'robnya apa? ·
Kenapa? · Matbu'nya mana?

ᵃ = `sekali_per_sesi`

---

## 8. Yang muncul gratis dari skema ini

Semua ini nol kode tambahan — hanya query. Inilah alasan sistem dibangun.

- **Profil kelemahan santri.** *"Satria: 'kalimat apa' 90%, 'kenapa pakai tanda
  itu' 40%."* → dia hafal, belum paham. Diagnosis yang selama ini hanya ada di
  kepala ustadz, sekarang tertulis dan bisa diwariskan.
- **Peta kelas.** Anak-tangga terlemah se-kelas → bahan musyawarah asatidz
  besok pagi. Kurikulum yang menyesuaikan data, bukan jadwal.
- **Kalibrasi penguji** — dengan satu syarat yang wajib disadari. Satu ustadz
  memegang satu kelompok, jadi membandingkan rata-rata antar penguji itu RANCU:
  selisihnya bisa murni karena siapa yang ia dapat, bukan bagaimana ia menilai.
  Yang sah hanya perbandingan **berpasangan** — nilai atas santri *yang sama*
  dibanding penguji lain — dan itu hanya ada kalau **kelompoknya berotasi**.
  Rotasi bukan sekadar urusan jadwal; itu satu-satunya cara keadilan penilaian
  bisa diukur sama sekali.
- **Soal yang menjebak semua orang** → bukan santrinya yang salah, ibarat itu
  memang berat atau rubriknya kabur. Umpan balik untuk penyusun soal.
- **Pengulangan cerdas (Fase 3).** Bukan "ulangi kata yang salah" — tapi
  *sajikan lafad lain yang menguji anak-tangga yang lemah*. Melatih konsep,
  bukan menghafal jawaban. Ini yang buku dan kertas tidak akan pernah bisa.

---

## 9. Sengaja tidak dibangun sekarang

| Ditunda | Alasan | Tambah kalau |
|---|---|---|
| Backend & akun | 20 santri muat di `localStorage` | Fase 2, saat lebih dari satu HP |
| Aplikasi santri | Santri tidak pegang HP | L3, lewat lab/perangkat pengawas |
| Rekam audio | Butuh storage + moderasi | L3, saat async jadi produk |
| Penilaian oleh AI | **Alasan kultural, bukan teknis** | (lihat bawah) |
| Framework/React | Satu layar, tanpa routing | Saat layarnya lebih dari 5 |
| Sistem jenjang/kurikulum | Cuma 2 tingkat, pemetaannya 5 baris | Ada tingkat ke-3 dengan pola beda |
| Kenaikan tingkat otomatis | Naik BK1→BK2 keputusan asatidz, bukan rumus | Kalau nanti mereka *minta* usulan |
| Multi-pesantren | Belum satu pesantren pun terbukti | L4 |
| Ekspor Excel bergaya | Cetakan mirip leger sudah cukup | Kalau diminta |

**Soal AI — putuskan sekarang, jangan menunggu ditolak:** i'rob punya sanad dan
otoritas. Sistem yang *menilai* bacaan kitab akan ditolak pesantren, dan
memang seharusnya. Posisi AI di sistem ini hanya dua:
(a) menyusun **draf kunci jawaban** i'rob untuk diverifikasi ustadz, dan
(b) memilih soal berikutnya sesuai kelemahan.
**AI menyiapkan, ustadz memutuskan.** Jangan pernah dibalik.

---

## 10. Risiko khas pesantren

| Risiko | Penanganan |
|---|---|
| Ustadz sepuh enggan pakai aplikasi | Satu-satunya obat: **lebih cepat dari kertas**. Ketuk-saja, nol ketik. Ukur di Fase 1, bukan diasumsikan. |
| Dianggap mengurangi adab / talaqqi | Sistem tidak menggantikan majelis — ia mencatat. Bingkai sebagai *leger*, bukan *aplikasi ngaji*. |
| Legitimasi | Restu satu kyai/ustadz senior di depan. Mulai dari penguji yang menyusun dokumen ini sendiri. |
| Sinyal mati | Offline-first sejak Fase 0. Bukan tambahan belakangan — itu ulang tulis total. |
| Data santri (anak di bawah umur) | Tanpa nama di layar publik/demo. Ekspor selalu berpemilik. Ini batas keras. |
| HP penguji hilang/rusak sebelum sinkron | Ekspor JSON setiap akhir sesi, dari Fase 0. |
| Proyek mangkrak setelah semangat awal | Fase 2 (harian) adalah pengunci. Kalau berhenti di ujian saja, dipakai 2× setahun lalu dilupakan. |

---

## 11. Ukuran keberhasilan

| Fase | Lulus kalau | Gagal kalau |
|---|---|---|
| 0 | Satu ujian penuh selesai tanpa kertas | Ada penguji balik ke kertas di tengah |
| 1 | Waktu per santri ≤ kertas; 4/4 penguji mau pakai lagi | Lebih lambat → berhenti, perbaiki UX |
| 2 | ≥ 60% sesi sorogan harian tercatat selama 1 bulan | < 30% → alurnya masih terlalu berat |
| L3 | 1 ustadz menilai ≥ 20 santri/minggu | Async terasa lebih capek dari tatap muka |

---

## 12. Mulai besok

1. Seed data: 20 nama santri + tingkatnya, 4 penguji, 60 soal BK2 (beri `tipe`
   satu per satu, jangan dihitung dari nomor), 4 tangga BK2 + 1 tangga BK1.
   Satu file JSON. **Setengah hari.**
2. `leger.html` — dua layar masuk (BK1 ketuk-kata / BK2 pilih nomor), satu
   layar tangga, satu ekspor. **Dua hari.**
3. Uji dengan satu ustadz, 1 santri, 10 lafad. Catat detiknya.
   Bandingkan dengan kertas. **Satu jam.**
4. Kalau lebih cepat → pakai di ujian berikutnya. Kalau tidak → perbaiki alur,
   jangan tambah fitur.

Yang paling menentukan bukan kodenya. Yang menentukan adalah **penguji pertama
merasa dibantu, bukan direpotkan.** Selebihnya menyusul sendiri.
