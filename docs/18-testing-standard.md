# 18 — Standar Pengujian

## Dua aturan yang lahir dari kegagalan nyata

### 1. Uji lewat pintu yang dipakai pengguna

`klaim_ustadz` lolos semua pengujian dan tetap mati. Pengujinya menyetel
`ustadz.auth_id` lewat `UPDATE` alih-alih memanggil RPC-nya, jadi ia menguji
**sekeliling** jalurnya. Fungsinya sudah rusak sejak migrasi sebelumnya —
badan `plpgsql` diikat per nama saat dijalankan, dan nama itu sudah pindah
schema. Baru meledak di tangan ustadz pertama.

**Aturan:** kalau sebuah jalur dipakai lewat pintu X, ujilah lewat pintu X.

### 2. Test harus bisa membedakan benar dari salah

Test yang lolos untuk implementasi benar **maupun** salah adalah test tumpul.
Untuk logika yang gagal tanpa gejala, uji juga bahwa rumus keliru menghasilkan
angka **berbeda**, dan pasang penjaga ketumpulan:

```ts
expect(benar).toBe(75)
expect(keliru).toBe(67.9)
expect(benar).not.toBe(keliru)
```

`db/010_check_kalibrasi.sql` melangkah lebih jauh: fixture-nya dirancang agar
metrik polos dan metrik berpasangan menunjuk **orang yang berbeda**, dengan
assert yang gagal kalau suatu saat keduanya menunjuk orang yang sama.

## Apa yang diuji di mana

| Jenis | Perkakas | Letak |
|---|---|---|
| Aturan nilai, tangga, pembagian, peringkasan | Vitest | `test/*.test.ts` |
| View Postgres | `do $$ … $$` + `assert` | `db/*_check*.sql` |
| RPC | Panggilan sungguhan + `set local role authenticated` | `db/*_check*.sql` |
| RLS | Hitung baris sebagai `authenticated`, sebelum & sesudah terhubung | `db/016` |
| Tata letak, target sentuh | Pengukuran di browser | manual, wajib dilaporkan |

Logika sepele satu baris tidak butuh test. YAGNI berlaku juga untuk test.
Tanpa framework tambahan, tanpa fixture berlapis, tanpa mock yang rumit.

## Bentuk test domain

Murni, cepat, tanpa I/O. Suntikkan ketergantungan supaya deterministik:

```ts
const tetap: Pengacak = daftar => [...daftar]   // pengganti Math.random
bagikanBK2(bank, 2, tetap)
```

Nama test menyebut **aturannya**, bukan nama fungsinya:

```
✓ menghitung dibantu sebagai setengah, bukan nol atau satu
✓ tidak menghukum langkah yang dilewati
✓ merata-ratakan per soal, bukan seluruh langkah
✓ LEWATI maju tanpa meninggalkan baris apa pun
✓ menimbang dengan jumlah pengamatan, bukan merata-ratakan persentase
```

Test yang namanya `test nilaiSoal` tidak memberi tahu apa yang rusak saat gagal.

## Bentuk check SQL

Aman dijalankan ulang: sisipkan data uji, assert, lalu batalkan seluruhnya
dengan exception bernama:

```sql
do $$
declare …
begin
  -- sisipkan data uji
  assert <kondisi>, format('<pesan dengan angka nyata>', v);
  raise exception 'NAMA_OK_ROLLBACK | <angka kunci untuk dibaca sekali lihat>';
end $$;
```

Pesan akhir membawa angka pentingnya, sehingga hasilnya terbaca tanpa membuka
apa pun. Kegagalan assert menyebut nilai yang didapat, bukan hanya "gagal".

## Check yang ada dan yang dipagarinya

| Check | Yang dipagari | Angka kunci |
|---|---|---|
| `db/003_check.sql` | Urutan rata-rata nilai; `dibantu`=0.5; langkah dilewati | 75.0 vs 67.9 |
| `db/016_check_hubungkan.sql` | Penghubungan lewat RPC sungguhan; RLS buta total | 0 → 20 santri |
| `db/010_check_kalibrasi.sql` | Kalibrasi berpasangan; pembalikan tanda | polos 56.7/70.0 vs pasangan +50/−50 |
| `db/014_check_kenaikan.sql` | Kebocoran lintas kelas; dua tes wajib; tes ulang terbaru; potret nilai; penjaga alasan | daring 100, luring 90, → BK2 |

## Pengukuran browser: diukur, bukan dilihat

"Kelihatan baik" bukan verifikasi. Yang wajib diukur pada 375 px:

```js
kata.every(r => r.width >= 44 && r.height >= 44)   // target sentuh
jarak.every(j => j > 0)                            // celah antar target
document.body.scrollWidth <= innerWidth            // tanpa luberan
```

Dua bug nyata hanya tertangkap begini: kata Arab pendek selebar 27 px, dan celah
antar kotak sentuh 0 px karena Vue membuang whitespace `v-for`.

Kalau halaman terkunci auth sehingga tidak bisa diukur langsung: ekstrak
komponennya, buat halaman pratinjau sementara dengan data contoh, ukur, lalu
**hapus halaman pratinjaunya**. Ekstraksi komponennya boleh tetap — itu memang
perbaikan.

## Gerbang penuh

```bash
npm test            # 27 tes domain
npm run typecheck   # vue-tsc strict — dua bug nyata tertangkap di sini
npm run build       # produksi + PWA
```

Plus check SQL yang relevan. Tidak ada "sebagian lolos" (R15).

## Yang dilarang

- Menghapus atau melonggarkan test supaya hijau.
- Menyatakan "sudah diuji" untuk jalur yang diuji dari samping (R17).
- Menambah RPC tanpa check lewat panggilan sungguhan.
- Meringkas kegagalan. Tempelkan keluarannya.
- Menandai fitur selesai dengan `typecheck` merah, sekecil apa pun.
