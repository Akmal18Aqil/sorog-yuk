# 14 — Memori Proyek

Apa yang harus diingat lintas sesi, di mana disimpannya, dan apa yang **tidak**
perlu diingat.

## Tempat penyimpanan

| Isi | Tempat | Kenapa di situ |
|---|---|---|
| Aturan yang tidak boleh dilanggar | `docs/00-project-rules.md` | Dibaca duluan, mengikat semua |
| Domain & kosakata | `docs/01-system-overview.md` | Istilah pesantren tidak bisa ditebak dari kode |
| Keputusan arsitektur + alasannya | `docs/05-architect-agent.md` | Supaya tidak dibongkar tanpa sadar |
| Rencana produk & fase | `PLAN.md` | Milik pemilik proyek, bukan agen |
| Cara memakai & menjalankan | `README.md` | Pembaca pertama |
| **Kenapa** sebuah baris SQL begitu | Komentar di `db/*.sql` | Paling dekat dengan yang dijelaskan |
| Jebakan yang sudah memakan korban | `docs/09-debug-agent.md` (tabel gejala→akar) | Tempat orang mencari saat panik |
| Utang teknis yang disengaja | komentar `ponytail:` di kode | Terpanen otomatis, tidak jadi "nanti" selamanya |

## Aturan: alasan hidup dekat dengan kodenya

Komentar SQL di repo ini menjelaskan **kenapa**, bukan apa. Contoh yang wajib
dipertahankan bentuknya:

- `db/006` menjelaskan pengikatan nama `plpgsql` — itulah yang menyelamatkan
  orang berikutnya dari bug yang sama.
- `db/008` menjelaskan kenapa kalibrasi harus berpasangan.
- `db/013` menjelaskan kenapa nilai dipotret saat keputusan.
- `db/015` menjelaskan kenapa kode klaim dihapus dan apa yang menggantikannya.

Memindahkan alasan-alasan ini ke dokumen terpisah adalah kemunduran. Yang di
`docs/` adalah ringkasan dan aturan; yang di kode adalah alasan lokalnya.

## Yang TIDAK perlu diingat

- Struktur berkas — sudah terbaca dari repo.
- Riwayat perbaikan — sudah ada di `db/` bernomor dan di git.
- Apa yang sebuah fungsi lakukan — sudah terbaca dari fungsinya.
- Detail percakapan. Yang bertahan hanya keputusan dan alasannya.

Menuliskan hal-hal ini ke memori membuat memori jadi berisik dan akhirnya tidak
dibaca sama sekali.

## Yang wajib dicatat setelah setiap insiden

Setiap kali ada bug yang **lolos dari pengujian**, tiga hal wajib ditulis:

1. Gejala → akar, ke tabel di `09-debug-agent.md`.
2. Aturan baru di `00-project-rules.md`, kalau akarnya bisa terulang di tempat
   lain. (Contoh: R5 lahir dari bug `klaim_ustadz`; R8 dari bug generator seed.)
3. Check yang akan menangkapnya, di `test/` atau `db/`.

Insiden tanpa ketiganya akan terulang.

## Utang yang disengaja

Penyederhanaan yang memotong sudut nyata ditandai komentar `ponytail:` beserta
batas atas dan jalur peningkatannya. Contoh yang ada:

```sql
-- ponytail: subquery skalar dijalankan per grup. Tidak masalah utk puluhan
-- penguji; ganti ke CTE kalau sudah ratusan.
```

Aturannya: tandai batasnya, jangan sembunyikan. Penyederhanaan tanpa batas
tertulis adalah bug yang belum ketemu.

## Konteks yang tidak ada di kode dan mudah hilang

- **Sumber teks Arab adalah `.docx` asatidz**, bukan hasil ketik ulang. Satu
  harakat meleset = soal yang berbeda. `tools/buat_seed.py` membacanya langsung
  dan berhenti kalau kedua salinan di dokumen berbeda satu huruf pun.
- **Kelompok berotasi, dan rotasi itu wajib** — bukan urusan jadwal, tapi
  satu-satunya cara keadilan penilaian bisa diukur.
- **Santri tidak punya perangkat.** Semua rancangan UI berangkat dari sana.
- **Ukuran keberhasilan bukan kelengkapan fitur**, tapi apakah penguji pertama
  merasa dibantu, bukan direpotkan.
