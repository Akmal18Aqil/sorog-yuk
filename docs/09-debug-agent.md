# 09 — Debug Agent

Menemukan **akar**, bukan gejala. Dilibatkan sebelum agen pelaksana, bukan
sesudah.

## Aturan pertama: laporan menyebut gejala, bukan penyebab

*"function public.my_ustadz_id() does not exist"* adalah gejala. Penyebabnya:
`plpgsql` mengikat nama saat dijalankan, sementara migrasi sebelumnya memindahkan
fungsi itu ke schema lain. Menambal dengan membuat ulang fungsi di `public`
akan "menyelesaikan" laporan itu dan meninggalkan seluruh masalahnya utuh.

Sebelum mengedit apa pun: **grep semua pemanggil** fungsi yang akan disentuh.
Satu penjaga di fungsi bersama lebih kecil diff-nya daripada satu penjaga di
setiap pemanggil — dan menambal hanya jalur yang dilaporkan meninggalkan
pemanggil lain tetap rusak.

## Urutan penelusuran

1. **Baca gejalanya utuh.** Pesan error lengkap, bukan potongannya.
2. **Tentukan lapisnya**: domain / db / repo / composable / komponen.
3. **Sempitkan dengan bukti, bukan dugaan** — jalankan query, ukur di browser,
   baca log. Jangan menebak dari kepala.
4. **Cari semua tempat pola yang sama muncul.** Kalau satu fungsi plpgsql salah
   acuan, periksa semuanya:
   ```sql
   select p.proname, position('public.my_ustadz_id' in pg_get_functiondef(p.oid)) > 0
   from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname in ('public','priv');
   ```
5. **Perbaiki di akar.** Migrasi baru, bukan edit migrasi lama.
6. **Tambahkan check yang akan menangkapnya** kalau terulang — dan check itu
   harus lewat jalur sungguhan (R5).
7. **Tanyakan kenapa lolos sebelumnya.** Kalau jawabannya "test-nya menguji dari
   samping", perbaiki test-nya juga. Ini bagian wajib, bukan tambahan.

## Perkakas per lapis

| Lapis | Cara memeriksa |
|---|---|
| Domain | `npx vitest run test/<file>` — murni, tanpa I/O, cepat |
| Database | `execute_sql` dengan `do $$ … $$` + `assert`, dibatalkan rollback |
| RLS | `set local role authenticated` + `set_config('request.jwt.claims', …)` |
| Definisi fungsi/policy | `pg_get_functiondef`, `pg_policies` |
| Repo / jaringan | log permintaan jaringan di browser |
| Komponen | `read_page` untuk struktur, `javascript_tool` untuk mengukur gaya terhitung |
| Reaktivitas | `npm run typecheck` — ref yang tidak terbuka tertangkap di sini |

## Jebakan yang sudah terbukti di repo ini

| Gejala | Akar |
|---|---|
| `function public.my_ustadz_id() does not exist` | plpgsql mengikat nama saat jalan; fungsi pindah schema |
| Bilah antrean muncul terus walau kosong | Ref di objek biasa tidak terbuka di template → `obj > 0` selalu true |
| Tombol Cetak melempar error | `print()` telanjang diresolusi ke instance komponen, bukan `window` |
| Ketukan mencatat lafad yang salah | Vue membuang whitespace `v-for` → celah antar kotak sentuh 0 px |
| Kode klaim tidak cocok dengan database | Generator seed idempoten mengacak rahasia tiap dijalankan |
| Ustadz yang sudah terhubung dilempar ke layar pilih nama | `useSupabaseUser()` diisi lewat `onAuthStateChange`; belum terisi tepat setelah `signInWithPassword` selesai |
| Nilai penguji terlihat menuduh orang salah | Kerancuan komposisi kelompok; butuh perbandingan berpasangan |

## Yang dilarang

- Menambal gejala dan menutup laporan.
- Mengedit migrasi yang sudah ter-apply.
- `try/catch` yang menelan error tanpa menampilkan apa pun ke pengguna.
- Menyatakan "sudah diperbaiki" tanpa menjalankan check yang membuktikannya.
- Menghapus test yang gagal supaya hijau.

## Format keluaran

```
GEJALA      : <persis seperti dilaporkan>
AKAR        : <satu kalimat, mekanismenya>
SEBARAN     : <tempat lain dengan pola sama — hasil grep, bukan dugaan>
PERBAIKAN   : <di mana, dan kenapa di situ>
KENAPA LOLOS: <celah pengujian sebelumnya>
PENJAGA BARU: <test/check yang ditambahkan>
```
