# 02 — Arsitektur

## Arah ketergantungan

Satu arah, dan **domain tidak bergantung pada apa pun**:

```
pages/  ──▶  composables/  ──▶  utils/repo  ──▶  Supabase (PostgREST + RPC)
                  │
                  └──────▶  shared/domain/   (murni, teruji, nol I/O)
```

| Lapis | Isi | Aturan |
|---|---|---|
| `shared/domain/` | `nilai` `tangga` `pembagian` `ringkasan` | Murni. Tanpa Vue/Supabase/I/O. **Semua diuji.** |
| `shared/types/` | `database.ts` (generate) · `sorogan.ts` (union domain) | Batas anti-korupsi |
| `app/utils/repo.ts` | Satu-satunya titik sentuh Supabase | Menerima klien sebagai argumen |
| `app/utils/antrean.ts` | Antrean kirim offline | Factory; bisa diuji dengan klien palsu |
| `app/composables/` | Keadaan reaktif dan penjahitan | **Tanpa aturan bisnis** |
| `app/components/` | Tampilan | Tanpa akses data |
| `app/pages/` | Rute + komposisi | Tanpa aturan bisnis |

Pelanggaran yang paling sering terjadi: aturan bisnis merembes ke composable
atau komponen. Kalau sebuah aturan bisa dijelaskan tanpa menyebut layar, ia
milik `shared/domain/`.

## Kenapa domain dipisah keras

Urutan tangga, arti "lewati", urutan rata-rata nilai, dan pembagian merata per
tipe adalah **aturan ilmu alat** yang datang dari lembar asatidz — bukan detail
tampilan. Ditaruh di `shared/domain/` supaya bisa diuji tanpa merender apa pun,
dan supaya tidak ikut berubah setiap kali UI dirombak.

Rumus nilai memang hidup di **dua tempat**: TypeScript (nilai berjalan saat
offline) dan view Postgres (laporan). Duplikasi itu disengaja — layar harus tetap
menunjukkan nilai tanpa sinyal — tapi berarti keduanya bisa menyimpang
diam-diam. Karena itu keduanya **dipaku ke skenario yang sama persis**:
`test/nilai.test.ts` dan `db/003_check.sql` harus menghasilkan 75.0 dan 67.9.

## Batas anti-korupsi

Di Postgres, `tipe` / `verdict` / `tingkat` adalah `text`, jadi TypeScript
melihatnya `string` — dan `string` membiarkan salah ketik lolos sampai runtime.
`repo.ts` mempersempitnya jadi union dan **melempar error keras** kalau ada nilai
asing: artinya migrasi dan aplikasi tidak sinkron, dan itu harus ketahuan saat
memuat, bukan di tengah ujian.

Nama kolom sengaja **tidak** diubah ke camelCase. Penggantian nama itu kosmetik
dan hanya menambah lapisan pemetaan yang bisa salah. Yang dibeli di batas ini
adalah keamanan tipe, bukan gaya penulisan.

## Model data

```
kelas ──┬── santri ──┬── kelompok_santri ── kelompok
        │            ├── tes_offline          │
        │            └── kenaikan             │
        └── soal ── ibarat ── kitab           │
                                              │
ustadz ── sesi ────────────────────────────────┘
            └── penilaian ── jawaban ── langkah
```

**Tabel inti: `jawaban`.** Semua nilai dan analitik diturunkan dari sana.
Tidak ada kolom `nilai` di tabel mana pun (R1).

`langkah` adalah rubrik, dikunci `(tipe, urutan)` — satu tangga dipakai belasan
soal (R4).

**Penugasan ustadz→kelompok tidak disimpan.** Justru karena berputar: kolom
"penanggung jawab" akan basi terus dan menuntut admin merawatnya. Ustadz memilih
kelompok saat memulai sesi, `sesi.kelompok_id` merekamnya, dan riwayat siapa
memegang apa tetap terbaca penuh dari tabel `sesi`. Rotasi jadi gratis.

`kelas.kode` ('BK1'/'BK2') dipakai sebagai kunci relasi, bukan id angka, supaya
seluruh kode aplikasi yang sudah ada tetap berbicara 'BK1'/'BK2'. Referential
integrity menggantikan CHECK, sehingga menambah Kelas 3 nanti cukup satu INSERT.

## View: seluruh perhitungan hidup di sini

| View | Isi |
|---|---|
| `v_nilai_soal` | Nilai per soal = rata-rata langkah **yang tercatat** |
| `v_nilai_santri` | Rata-rata **nilai soal** — bukan rata-rata seluruh langkah (R2) |
| `v_kelemahan_langkah` | Anak-tangga terlemah per santri |
| `v_soal_sulit` | Soal yang menjebak semua orang |
| `v_kalibrasi_penguji` | Selisih **berpasangan** antar penguji |
| `v_kesiapan_naik` | Kesiapan dua tes vs ambang kelas |

Semua view pakai `security_invoker = on` sehingga RLS tabel di bawahnya tetap
berlaku.

## Kalibrasi penguji: satu jebakan statistik

Membandingkan rata-rata antar penguji hanya sah kalau mereka menilai santri yang
sebanding. Begitu **satu ustadz memegang satu kelompok**, selisihnya bisa murni
karena *siapa yang ia dapat*, bukan *bagaimana ia menilai* — dan angkanya tetap
terlihat meyakinkan sambil menuduh orang yang salah.

Rotasi kelompok jugalah obatnya: kalau santri yang sama pernah dinilai penguji
berbeda, perbandingannya bisa **berpasangan** — nilai seorang penguji atas santri
tertentu vs nilai penguji lain atas santri yang sama.

`db/010_check_kalibrasi.sql` memagari ini dengan fixture yang sengaja dibuat agar
kedua metrik menunjuk **orang yang berbeda**: rata polos A=56.7 B=70.0 (menuduh
B longgar), berpasangan A=+50 B=−50 (A yang longgar). Selama belum ada irisan,
`selisih_terkalibrasi` bernilai `null` — jujur bahwa belum bisa dibandingkan.

**Konsekuensi kebijakan:** rotasi kelompok bukan sekadar urusan jadwal. Itu
satu-satunya cara keadilan penilaian bisa diukur sama sekali.

## Keamanan

- **RLS aktif di semua tabel.** Akun login yang belum terhubung ke ustadz melihat
  **0 santri, 0 soal, 0 kode** — diuji langsung, bukan diasumsikan.
- Penghubungan identitas: ustadz memilih namanya sendiri lewat
  `hubungkan_ustadz()`, yang menolak nama yang `auth_id`-nya sudah terisi.
  **Pendaftaran di Supabase wajib tertutup** — itulah pintu utamanya.
- Helper policy (`priv.is_ustadz`, `priv.my_ustadz_id`) berada di schema `priv`
  yang tidak diekspos PostgREST. `SECURITY DEFINER` — wajib, kalau tidak policy
  pada `ustadz` jadi rekursif.
- Semua ustadz boleh **melihat** sesi satu sama lain (kalibrasi butuh itu),
  hanya pemilik boleh **mengubah**.
- RPC pengubah data pakai `SECURITY INVOKER` supaya RLS tetap satu-satunya
  penjaga.

## Model offline

1. Soal selesai → payload masuk antrean `localStorage` **seketika**.
2. Antrean dikirim saat sinyal ada, event `online`, dan tiap 15 detik.
3. RPC `simpan_penilaian` **aman diulang** (upsert per `(sesi, santri, urutan)`,
   jawaban diganti total) → kirim ulang tidak menggandakan.
4. Setelah 5 gagal beruntun, satu item dipindah ke daftar **macet** agar tidak
   menyumbat sisanya. Data tidak dibuang, jumlahnya ditampilkan.
5. **Kemajuan sesi juga disimpan.** Tanpa itu, reload di tengah sesi memulai
   penomoran dari 1 lagi dan menimpa penilaian yang sudah tersimpan —
   menghasilkan rekaman campuran yang tidak ketahuan salahnya.
6. Service worker men-cache shell aplikasi. **Panggilan Supabase tidak pernah
   di-cache** (R6).

## Yang sengaja tidak ada

Tanpa state manager (Pinia) — `useState` cukup untuk 4 halaman. Tanpa lapis
"service" antara composable dan repo — tidak ada yang perlu diabstraksi. Tanpa
backend sendiri — Postgres + RLS + RPC sudah jadi backend-nya. Tanpa i18n —
satu bahasa, satu pesantren.
