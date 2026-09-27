# 23 — Master Data: Santri, Kelas Sorogan, Mentor

Rancangan master data operasional sorogan. Melengkapi `22-kelola-user.md`.
Status: **D1–D4 dan G1–G2 selesai** (migrasi 019, 025–030; UI di
`app/pages/admin/kelola-user.vue` dan `app/utils/repo.ts`).
**G3 / D5 belum diputuskan** — lihat bagian 4.


---

## 1. Glosarium (istilah → skema)

| Istilah yang dipakai | Arti di sistem | Tabel |
|---|---|---|
| Santri | Peserta didik | `santri` |
| Kelas sorogan | Rombel yang dipegang satu mentor, berganti-ganti | `kelompok` |
| Mentor (penyorog) | Ustadz yang menyimak sorogan | `ustadz` |
| Kelas / jenjang | BK1, BK2 (sudah master data sejak `012`) | `kelas` |

Skema tetap memakai nama `ustadz`/`kelompok`. Rename tabel demi label =
migrasi + ubah seluruh kode. Itu bukan lazy, itu mahal. Label "Mentor"
hanya di UI.

---

## 2. Audit: yang sudah ada

| Entitas | Tabel | RPC CRUD | Halaman admin |
|---|---|---|---|
| Santri | `santri` (nama, tingkat→kelas, auth_id) | tambah/ubah/hapus (`018`) | kelola-user |
| Mentor | `ustadz` (nama, auth_id, role) | tambah/ubah/hapus | kelola-user |
| Kelas | `kelas` (kode, nama, urutan, ambang_online, ambang_offline) | penuh (`018`) | kelas |
| Kelompok | `kelompok` + `kelompok_santri` | penuh + kelola anggota (`018`) | kelompok |

Sudah benar dan tidak diutak-atik:
- Satu santri satu kelompok (unique index di `kelompok_santri`, `008`).
- Penugasan mentor → kelompok sengaja **tidak** disimpan (`008`); riwayat
  terbaca dari `sesi.kelompok_id`.
- Nilai tidak pernah disimpan (R1); ambang kenaikan sudah data, bukan
  angka di kode (`012`).

---

## 3. Kesenjangan (temuan audit)

**G1. Santri lulus/keluar tidak bisa dikeluarkan dari daftar.**
`hapus_santri` = hard DELETE, dan gagal (RESTRICT) kalau santri sudah punya
sesi. Akibat: daftar operasional tercemar nama yang sudah tidak ada.
Yang dibutuhkan bukan hapus, melainkan status.

**G2. Mentor nonaktif tidak ada.**
Sama: tidak ada cara menandai mentor yang sudah tidak mengajar tanpa
menghapus barisnya (dan merusak riwayat sesi).

**G3. Pendaftaran santri mandiri memberi akses seketika.**
`daftar_santri` (`017`) mengisi `santri.auth_id` langsung dari `auth.uid()`
dengan nama bebas. Siapa pun yang bisa signup bisa mengaku "Satria" dan
langsung membaca nilainya. Ini lubang yang dideskripsikan `22` bagian 3 --
belum ditutup.

**G4. Pindah kelompok hanya nyaman dari halaman kelompok.**
Fungsinya ada (tambah/hapus anggota). Tinggal perhalus di HP.

**Bukan kesenjangan** (sengaja tidak dibuat):
- Riwayat kelompok santri -- terbaca dari `sesi.kelompok_id`.
- Tahun ajaran / periode -- YAGNI sampai ada kebutuhan nyata.
- Identitas santri selain nama (NIS, TTL, alamat) -- R9: data anak di bawah
  umur, minimal saja.
- Hierarki peran di bawah superadmin -- `22` bagian 5: jangan dulu.

---

## 4. Keputusan desain

**D1. Tambah `aktif boolean not null default true` di `santri` dan `ustadz`.**
Nonaktifkan bukan hapus. Daftar operasional, mulai sesi, dan laporan hanya
menampilkan yang aktif; riwayat nilai tetap utuh (R1). Satu kolom, bukan
tabel status baru.

**D2. RPC `set_aktif_santri` / `set_aktif_ustadz` (superadmin saja).**
Hapus fisik dipertahankan hanya untuk baris yang belum punya riwayat
(misal salah ketik saat input). RPC hapus menolak dengan pesan jelas bila
ada `sesi` terkait -- gagal dengan kalimat lebih baik daripada error FK
mentah.

**D3. Pindah kelompok tetap operasi `kelompok_santri` biasa.**
Tidak ada tabel riwayat. Di UI: cari santri, pindah.

**D4. Label UI "Mentor", skema tetap `ustadz`.**
Satu baris glosarium di dokumen ini, nol migrasi.

**D5. G3 butuh keputusan pesantren (tidak bisa ditentukan sendiri):**
- Opsi A (rekomendasi): tutup sesuai `22` -- pendaftaran menjadi klaim +
  persetujuan superadmin (`pendaftaran`, `setujui_pendaftaran`,
  `tolak_pendaftaran`).
- Opsi B: matikan pendaftaran mandiri total; semua akun santri dibuat
  superadmin. Paling kecil, tapi superadmin mengetik ~20 akun manual.
- Opsi C: biarkan seperti sekarang. Tidak direkomendasikan -- kalau dipilih,
  risikonya tercatat di sini sebagai keputusan sadar, bukan kelalaian.

> **Status: belum diputuskan.** Opsi A/B/C sama-sama mengubah perilaku
> pendaftaran, dan itu keputusan pesantren, bukan teknis. Yang ada
> sekarang: `daftar_santri` (017) masih memberi akses seketika seperti
> semula, jadi risikonya **tercatat di sini** sebagai hal yang belum
> ditutup — bukan sesuatu yang lolos tanpa terlihat. Butuh keputusan
> sebelum ditutup.

---

## 5. Delta skema (migrasi `019`)

```sql
alter table santri add column aktif boolean not null default true;
alter table ustadz add column aktif boolean not null default true;
-- RLS tidak berubah: tetap hanya ustadz/superadmin yang membaca (R9).
-- Default true: data lama otomatis dianggap aktif, tanpa backfill.
```

---

## 6. Delta RPC

| RPC | Pemanggil | Tugas |
|---|---|---|
| `set_aktif_santri(p_id, p_aktif)` | superadmin | Toggle aktif santri |
| `set_aktif_ustadz(p_id, p_aktif)` | superadmin | Toggle aktif mentor |
| `pindah_kelompok(p_santri, p_kelompok)` | superadmin | Ganti anggota dalam satu operasi (opsional; bisa pakai dua RPC lama) |

Semua `SECURITY DEFINER`, validasi `priv.is_superadmin()`, diuji lewat
panggilan sungguhan (R5).

---

## 7. Delta UI (mobile-first, reuse komponen)

- `kelola-user`: toggle Aktif/Nonaktif + filter "sembunyikan nonaktif"
  (default sembunyi). Reuse `SantriBaris`, `ConfirmDialog`, `Toast`.
- `mulai`: daftar santri otomatis hanya yang aktif (filter di `ambilAcuan`,
  bukan di tiap halaman -- R6: acuan boleh di-cache, nilai tidak).
- `hasil` / `kenaikan`: tidak berubah -- riwayat tetap tampil, itu benar.
- Tidak ada halaman baru. Tidak ada warna/komponen baru. Ikuti yang ada.

---

## 8. Urutan pengerjaan (berkala, satu per satu)

1. Migrasi `019` + check SQL (kolom aktif; pastikan data lama default true).
2. RPC toggle aktif + perketat hapus. Uji lewat panggilan sungguhan (R5).
3. UI kelola-user: toggle + filter nonaktif.
4. UI mulai: filter aktif di `ambilAcuan`.
5. Keputusan G3 (butuh jawaban pesantren) -- implementasi terpisah, tidak
   digabung dengan 1--4.
6. Gates: `npm test`, `npm run typecheck`, `npm run build` + check SQL
   yang relevan (R15). Tidak ada "sebagian lolos".

---

## 9. Kriteria selesai

- Santri/mentor nonaktif hilang dari daftar operasional, tetap ada di riwayat.
- Hapus baris ber-riwayat ditolak dengan pesan jelas, bukan error FK mentah.
- R15 hijau. Tidak ada tabel/kolom baru selain `aktif`.
- D5 diputuskan dan tercatat (opsi apa pun yang dipilih).

> **Kriteria 1, 2, 3 terpenuhi; 4 belum.** `npm test` (27), `npm run
> typecheck`, dan `npm run build` hijau setelah perubahan. Pemeriksaan
> lewat panggilan sungguhan ke database pada 26/09/2026:
>
> | Yang diuji | Hasil |
> |---|---|
> | Hapus berriwayat (santri & ustadz) | ditolak: "sudah punya riwayat. Nonaktifkan, jangan hapus" |
> | Hapus tanpa riwayat | berhasil |
> | `set_aktif_*` oleh superadmin | berhasil; tidak aktif → nonaktif → aktif |
> | `set_aktif_*` oleh ustadz biasa | ditolak |
> | `set_aktif_ustadz` pada superadmin | ditolak: mengunci semua akses |
> | Santri nonaktif | hilang dari operasional, riwayat tetap utuh |
> | Mentor nonaktif | hilang dari daftar pilihan, raportnya tetap bisa dibaca |
> | `anon` memanggil `set_aktif_*` | ditolak: permission denied |
>
> D5 belum diputuskan (§4), jadi kriteria 4 masih terbuka.
