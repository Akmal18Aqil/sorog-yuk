# 01 — Gambaran Sistem

## Apa ini

Sistem digital untuk **sorogan** — setoran bacaan kitab santri kepada ustadz —
di pesantren. Menggantikan leger kertas tes lisan baca kitab.

Sumber kebenaran domainnya dua dokumen leger asli dari asatidz:
`Tes Lisan BK 1.docx` (tangga 9 pertanyaan per lafad) dan `Tes Lisan BK 2.docx`
(bank 60 soal tarkib, 4 tipe).

## Kosakata

| Istilah | Arti |
|---|---|
| **Sorogan** | Santri membaca/menyetor kitab langsung kepada ustadz, satu per satu |
| **Kitab** | Teks rujukan; di sini bank soalnya dari *Tarkib Umdah* |
| **Ibarat** | Satu potongan/kalimat dari kitab |
| **Lafad** | Satu kata yang ditanyakan (objek tes Kelas 1) |
| **Tarkib** | Susunan kalimat yang ditanyakan (objek tes Kelas 2) |
| **I'rob** | Kedudukan gramatikal kata dalam kalimat |
| **Tangga** | Runtutan pertanyaan yang harus dijawab untuk satu soal |
| **Anak-tangga / langkah** | Satu pertanyaan di dalam tangga |
| **Verdict** | Hasil satu langkah: `benar` / `dibantu` / `salah` |
| **Leger** | Lembar rekap nilai; bentuk yang dikenal asatidz dan kyai |
| **Kelompok** | Sekumpulan santri (5 orang) yang digarap satu ustadz per sesi |
| **Kelas / tingkat** | Jenjang: Kelas 1 (`BK1`) dan Kelas 2 (`BK2`) |

## Dua kelas, dan dua tes untuk naik

Ada **dua kelas**: `BK1` (Baca Kitab 1) dan `BK2` (Baca Kitab 2). Santri naik
**sesuai kemampuan**, bukan sesuai waktu, dan kenaikan menuntut **dua tes**:

| Tes | Siapa yang menjalankan | Tempatnya di sistem |
|---|---|---|
| **Tes daring (online)** | **Aplikasi ini** | Sesi dengan `mode = 'ujian'`; nilainya turun dari `v_nilai_soal` |
| **Tes luring (offline)** | Tatap muka, di luar aplikasi | Nilainya **dicatat** ke tabel `tes_offline` |

Keduanya wajib lolos ambang kelas yang sedang dijalani
(`kelas.ambang_online`, `kelas.ambang_offline`; bawaan 70). Baru setelah itu
santri muncul sebagai **usulan** kenaikan — dan asatidz yang memutuskan (R11).

Dua hal yang mudah luput dan sudah dipagari test:

- **Nilai harus dari materi kelas yang sedang dijalani.** Nilai ujian materi
  Kelas 2 tidak boleh ikut menghitung kenaikan santri Kelas 1. Kalau bocor,
  santri bisa naik karena nilai yang bukan haknya, dan angkanya terlihat wajar
  sepenuhnya. Lihat `db/014_check_kenaikan.sql`.
- **Tes ulang memakai nilai TERBARU**, bukan yang pertama atau yang terbaik.
  Baris lama tidak ditimpa supaya jejak perbaikan santri tidak hilang.

## Beda dua kelas bukan cuma tingkat kesulitan

| | Kelas 1 (`BK1`) | Kelas 2 (`BK2`) |
|---|---|---|
| Objek soal | satu **lafad** | satu **tarkib** |
| Asal soal | ditunjuk penguji dari ibarat | **bank tetap 60 soal** |
| Jumlah tangga | 1 (`lafad`, 9 langkah) | 4 (ismiyah / fi'liyah / nawasikh / tabi') |
| Layar penguji | **ketuk kata** pada ibarat | pilih nomor soal |
| Soal per santri | 10 (= 10 kolom leger kertas) | 8 (2 × 4 tipe) |

Karena alur UI-nya memang berbeda, `Tingkat` tetap union `'BK1' | 'BK2'` di
TypeScript meski `kelas` sudah jadi tabel. Yang jadi data adalah nama dan
ambangnya; yang jadi kode adalah bentuk interaksinya.

## Kenapa dibangun: yang kertas tidak bisa

Kertas menyimpan **satu angka per lafad**. Padahal penguji menanyakan 6–9
anak-tangga. Sekitar 90% informasi dibuang saat ditulis.

Sistem ini menyimpan verdict tiap anak-tangga, dan dari sana muncul sendiri:

- **Profil kelemahan santri** — *"'kalimat apa' 90%, 'kenapa pakai tanda itu'
  40%"* → dia hafal, belum paham. Diagnosis yang tadinya hanya ada di kepala
  ustadz, sekarang tertulis dan bisa diwariskan.
- **Peta kelas** — anak-tangga terlemah se-kelas, bahan musyawarah asatidz.
- **Soal yang menjebak semua orang** — berarti ibarat atau rubriknya yang perlu
  ditinjau, bukan santrinya.
- **Kalibrasi penguji** — masalah keadilan yang tak terlihat di kertas. Lihat
  batasan pentingnya di `02-architecture.md`.

Tiga data yang gratis dan tak ada di kertas: verdict `dibantu` ("ditunjuki dulu
baru bisa" — sinyal kemajuan paling informatif), **detik** tiap jawaban, dan
langkah yang **dilewati** (bukan nol).

## Master data

`santri` · `ustadz` · `kelas` · `kelompok` + `kelompok_santri` · `kitab` ·
`ibarat` · `soal` · `langkah` (rubrik).

Semuanya sudah ter-seed dari dokumen asli: 60 ibarat, 60 soal BK2, 41
anak-tangga, 20 santri, 4 kelompok × 5, 4 ustadz, 2 kelas.

**Belum ada UI CRUD master data.** Menambah santri tahun depan masih lewat SQL.
Ini item pertama di `20-roadmap.md`, dengan alasan penundaannya.

## Siapa penggunanya

> ⚠️ **Bagian ini sedang berubah.** Santri akan mengerjakan ujian daring di
> laptop, jadi mereka akan punya akun. Rencana penuh, keputusan yang menunggu
> pesantren, dan 27 tugas: [`21-peran-dan-ujian-santri.md`](21-peran-dan-ujian-santri.md).
> Uraian di bawah menggambarkan keadaan yang berjalan **hari ini**.

**Hanya ustadz.** Santri belum punya akun dan tidak memegang perangkat — di
banyak pesantren HP santri dilarang. Semua penilaian dioperasikan ustadz.
Aplikasi santri (setoran mandiri, rekaman audio) ada di roadmap lapis 3, bukan
sekarang.

## Bentuk aplikasinya

PWA satu halaman (Nuxt 4, `ssr: false`), dipasang ke layar utama HP ustadz,
**berfungsi penuh tanpa sinyal**. Data acuan di-cache, penilaian masuk antrean
lokal dan dikirim sendiri saat sinyal ada.
