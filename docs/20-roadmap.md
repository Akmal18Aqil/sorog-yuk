# 20 — Roadmap

Peta produk lengkap beserta alasannya ada di [`../PLAN.md`](../PLAN.md).
Dokumen ini adalah daftar kerja: apa berikutnya, dan **pemicu** kapan sesuatu
layak dikerjakan.

## Sudah jalan

- Leger digital tes lisan, BK 1 (ketuk kata) dan BK 2 (bank 60 soal)
- Verdict per anak-tangga + detik + langkah dilewati
- Alur kelompok: satu ustadz satu kelompok, rotasi gratis
- Offline penuh: antrean lokal, PWA, kemajuan sesi tersimpan
- Diagnostik: kelemahan langkah, soal sulit, kalibrasi **berpasangan**
- Leger cetak menyerupai lembar kertas
- Master data kelas + ambang kenaikan sebagai data
- Kenaikan kelas: dua tes, sistem mengusulkan, asatidz memutuskan
- 27 tes domain + 4 check SQL + typecheck strict

## Berikutnya

### 1. CRUD master data — **prioritas tertinggi**

Sekarang menambah santri, ustadz, atau memindahkan anggota kelompok masih lewat
SQL. Itu tidak akan bertahan melewati satu tahun ajaran.

Cakupan minimal: tambah/ubah santri · pindahkan santri antar kelompok ·
tambah/hapus kelompok · ubah ambang kelas.

**Pemicu: sekarang.** Ditunda selama pembangunan hanya karena data seed cukup
untuk membuktikan alur penilaiannya lebih dulu.

### 2. Putaran penuh dengan akun sungguhan

Alur daftar → klaim → nilai → cetak → kenaikan belum pernah dijalankan utuh dari
sisi browser oleh pengembang; yang teruji langsung adalah skema, RLS, rumus
nilai, dan seluruh RPC. **Lakukan sekali dengan satu santri sebelum dipakai
ujian betulan.** Ini bukan fitur, ini prasyarat.

### 3. Ukur waktu per santri vs kertas

Satu ustadz, satu santri, 10 lafad, pakai stopwatch. Kalau lebih lambat daripada
menulis tangan, **perbaiki alurnya dan jangan tambah fitur apa pun** sampai lebih
cepat (R12). Ini penentu hidup-matinya proyek, bukan metrik pelengkap.

### 4. Sorogan harian jadi kebiasaan

Mode `harian` sudah ada tapi belum dipakai rutin. Ujian lisan hanya 2× setahun;
sorogan tiap hari. Nilai sistem berkali-kali lebih besar kalau dipakai harian,
dan rekam jejak longitudinal santri baru muncul dari sana.

**Pemicu: setelah satu siklus ujian berhasil dilewati tanpa kertas.**

### 5. Kartu santri

Satu layar: kurva per anak-tangga sepanjang waktu, dibuka ustadz **sebelum**
menyorog. Datanya sudah lengkap tersimpan; ini murni pekerjaan tampilan.

**Pemicu: setelah data harian terkumpul minimal satu bulan** — sebelum itu
kurvanya kosong dan tidak berguna.

## Ditunda dengan sengaja

| Ditunda | Alasan | Tambah kalau |
|---|---|---|
| CI (GitHub Actions) | Satu orang yang commit; gerbang dijalankan manual | Ada commiter kedua |
| Ekspor CSV/Excel | Cetak leger sudah menjawab kebutuhan pembaca | Ada yang benar-benar meminta |
| Layar wali santri | Butuh kebijakan privasi dulu, bukan kode | Pesantren memutuskan kebijakannya |
| ~~Aplikasi santri~~ | **Asumsi ini sudah berubah** — santri akan ujian di laptop. Rencana penuh + 27 tugas ada di [`21-peran-dan-ujian-santri.md`](21-peran-dan-ujian-santri.md) | Sedang direncanakan |
| Rekam audio setoran | Butuh storage + moderasi + kebijakan | Sorogan async jadi produk (lapis L3) |
| Penilaian oleh AI | **Alasan kultural** — i'rob punya otoritas dan sanad | Tidak pernah dibalik: AI menyiapkan, ustadz memutuskan (R10) |
| Multi-pesantren | Belum satu pesantren pun terbukti pakai rutin | Lapis L4 |
| Kelas ke-3 dan seterusnya | Baru ada dua | Cukup INSERT ke `kelas` untuk datanya; alur UI-nya butuh kode karena bentuk soalnya beda |
| i18n | Satu bahasa, satu pesantren | Keluar dari pesantren ini |
| State manager (Pinia) | 5 halaman, `useState` cukup | Halaman lebih dari ~10 |

## Arah jangka panjang

| Lapis | Isi | Yang dibuka |
|---|---|---|
| **L1** — Leger digital | ✅ jalan | Data proses, diagnostik |
| **L2** — Sorogan harian | Berikutnya | Rekam jejak longitudinal, rapor wali |
| **L3** — Sorogan async | Santri merekam bacaan, ustadz menilai belakangan | **Rasio ustadz:santri dari 1:5 → 1:50** |
| **L4** — Platform | Multi-pesantren, bank kitab bersama, sanad digital | Skala keluar pesantren |

Nilai ekonominya ada di **L3**: sorogan macet karena jam ustadz, bukan karena
kurang aplikasi. Async memecah leher botol itu. L1 dan L2 adalah cara mendapatkan
data dan kepercayaan untuk sampai ke sana.

## Utang teknis yang diketahui

| Utang | Batas atas | Jalur peningkatan |
|---|---|---|
| Subquery skalar per grup di `v_kalibrasi_penguji` | Aman untuk puluhan penguji | Ubah ke CTE kalau sudah ratusan |
| `typescript` dipatok `~5.9` | Bukan pilihan, keharusan | Naikkan setelah `vue-tsc` mendukung TS 7 |
| Kemajuan sesi hanya di localStorage satu perangkat | Ustadz tidak berganti HP di tengah sesi | Simpan ke server kalau itu jadi kenyataan |
| Jumlah soal BK 2 = 8 (2 × 4 tipe) — **asumsi** | Dokumen BK 2 hanya memuat banknya | Konfirmasi ke asatidz; ubah `PER_TIPE_BK2` |

## Yang tidak akan dikerjakan

- AI yang menilai bacaan kitab (R10).
- Kenaikan kelas otomatis tanpa persetujuan asatidz (R11).
- Menyimpan nilai sebagai kolom (R1).
- Cache untuk data nilai (R6).
