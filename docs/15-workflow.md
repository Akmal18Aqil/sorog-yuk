# 15 — Alur Kerja

Dari permintaan sampai selesai. Satu permintaan, satu perubahan, satu laporan.

## Alur penuh

```
1  TERIMA      Orchestrator: lingkup, aturan yang mengikat, agen
2  PAHAMI      Baca kode yang disentuh. Telusuri alurnya utuh dulu.
3  PUTUSKAN    Architect (kalau menyentuh model data / aturan nilai / keamanan)
4  RENCANA     Planner: langkah + verifikasi tiap langkah
5  KERJAKAN    Backend / Frontend — dari dalam ke luar
6  UJI         QA: gerbang penuh + check yang relevan
7  PERIKSA     Security (kalau menyentuh RLS / data santri)
8  LAPOR       Reporter: angka apa adanya, termasuk yang belum diuji
```

Langkah 2 tidak boleh dipotong. Perubahan terkecil di tempat yang salah bukan
efisiensi — itu bug kedua.

## Urutan mengerjakan: dari dalam ke luar

```
aturan/domain → migrasi db → tipe → repo → composable → halaman → dokumen
```

Membangun UI sebelum aturannya pasti berarti UI dibongkar dua kali. Contoh nyata:
fitur kenaikan kelas dikerjakan `kelas` → `tes_offline`+`kenaikan`+view → RPC →
check → tipe → repo → halaman → dokumen. Tidak ada langkah yang perlu diulang.

## Alur perbaikan bug — berbeda

```
1  Baca gejala utuh (pesan error lengkap)
2  Debug: temukan AKAR, bukan gejala
3  Grep semua pemanggil fungsi yang akan disentuh
4  Perbaiki di akar — migrasi BARU, bukan edit migrasi lama
5  Tanyakan: kenapa ini lolos pengujian sebelumnya?
6  Tambahkan check lewat jalur sungguhan
7  Catat gejala→akar ke docs/09; tambahkan aturan ke docs/00 kalau bisa terulang
```

Langkah 5 dan 7 sering dilewati dan justru itu yang membuat bug berulang.

## Gerbang selesai

```bash
npm test            # 27 tes domain
npm run typecheck   # vue-tsc strict
npm run build       # produksi + PWA
```

Plus check SQL yang relevan, plus verifikasi browser (dan **pengukuran** kalau
menyentuh tata letak/target sentuh). Tidak ada "sebagian lolos" (R15).

## Kapan berhenti dan bertanya

Hanya kalau dua tafsir menghasilkan pekerjaan yang berbeda secara material.
Selain itu: ambil keputusan wajar, nyatakan asumsinya, lanjutkan.

Kalau sebagian lingkup terhalang: kerjakan sisanya **penuh**, lalu sebutkan
dengan jelas apa yang ditinggalkan dan kenapa. Mengecilkan lingkup adalah hak
pemilik proyek, bukan hak pelaksana.

## Definisi selesai

Sebuah perubahan selesai kalau:

- [ ] Melakukan yang diminta, tidak lebih dan tidak kurang
- [ ] Tidak melanggar `00-project-rules.md`
- [ ] Logika non-sepele meninggalkan satu check yang bisa dijalankan
- [ ] Gerbang penuh hijau
- [ ] Yang belum diuji dinyatakan, bukan didiamkan
- [ ] Dokumen ikut diperbarui kalau perilakunya berubah
- [ ] Migrasi di `db/` cocok dengan yang ter-apply di project

## Ritme rilis

Tidak ada jadwal. Yang menentukan kesiapan bukan kalender, tapi satu pertanyaan:
**apakah penguji merasa dibantu?** Ukur waktu per santri dibanding menulis
tangan. Kalau lebih lambat, perbaiki alurnya — jangan tambah fitur.
