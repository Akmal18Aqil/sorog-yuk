# 22 — Kelola User & Pendaftaran (rencana)

Peninjauan `hubungkan_ustadz`, dan rancangan penggantinya: **pendaftaran mandiri
hanya untuk santri**, akun ustadz dibuat superadmin lewat layar **Kelola User**.

Rencana, belum implementasi. Melengkapi [`21-peran-dan-ujian-santri.md`](21-peran-dan-ujian-santri.md).

---

## 1. Kenapa `hubungkan_ustadz` memang harus ditinjau

Fungsi itu memberi izin ke **semua akun login** (`grant execute … to authenticated`)
dan hanya menuntut dua hal: pemanggil belum terhubung, dan nama tujuan belum
dipakai. Saat ini masih ada **3 nama menganggur** (Ghofar, Rafli, Akmal).

Akibatnya: siapa pun yang berhasil mendaftar bisa memilih salah satu nama itu
dan **seketika jadi ustadz penuh** — 20 nama santri, seluruh nilai, sampai
wewenang menaikkan kelas.

Akar kekeliruannya satu kalimat:

> **Fungsi itu menyamakan "saya punya akun" dengan "saya orang ini".**

Dua hal itu harus dipisah, dan pemisahannya berlaku untuk **semua peran**, bukan
cuma ustadz.

## 2. Prinsip pengganti: mendaftar ≠ diberi identitas

| Tahap | Siapa yang melakukan | Hasilnya |
|---|---|---|
| **Mendaftar** | Calon pengguna sendiri, atau superadmin | Akun **buta** — nol baris dari tabel mana pun |
| **Menautkan** | **Hanya superadmin** | Akun terhubung ke baris `santri`/`ustadz`; baru di sini akses lahir |

Selama dua tahap ini terpisah, mendaftar jadi tindakan tak berbahaya — dan itu
yang membuat pendaftaran mandiri santri aman.

## 3. Tiga jalur akun

| Peran | Cara akun lahir | Boleh daftar sendiri? |
|---|---|---|
| **superadmin** | Dashboard Supabase, sekali saja | Tidak |
| **ustadz** | Dibuat superadmin di Kelola User | **Tidak** |
| **santri** | **Mendaftar sendiri** di layar masuk, lalu **disetujui** superadmin | Ya — tapi akunnya mati sampai disetujui |

### Bahaya kalau tahap persetujuan dilewatkan

Kalau santri boleh memilih namanya sendiri lalu langsung aktif, lubangnya
**20× lebih besar** daripada lubang ustadz sekarang: orang asing bisa mengaku
"Satria" dan mengerjakan ujiannya. Jadi memilih nama saat mendaftar hanya boleh
berstatus **klaim**, bukan pemberian.

### Bentuk yang disarankan: klaim + persetujuan

Saat mendaftar, santri memilih namanya dari daftar. Itu **tidak memberi apa pun** —
hanya mengisi `klaim_santri_id` supaya superadmin tahu siapa yang harus
dicocokkan. Superadmin menyetujui atau menolak.

Ini memecahkan masalah pencocokan yang nyata: ada **dua Fahmi** di daftar
(`Fahmi I` dan `Fahmi A.`). Tanpa klaim, superadmin hanya melihat alamat email
dan harus menebak.

## 4. Kendala keras: membuat akun butuh `service_role`

Membuat user auth (`auth.admin.createUser`) **hanya bisa dengan kunci
`service_role`**. Kunci itu menembus RLS sepenuhnya, jadi tidak boleh pernah
masuk browser (R9, `10-security-agent.md`).

Dan aplikasi ini `ssr: false` + `nuxt generate` → **tidak ada server sama sekali**
di artefak rilis. Jadi tombol "Tambah Ustadz" tidak bisa langsung membuat akun.

| Opsi | Cara kerja | Biaya | Catatan |
|---|---|---|---|
| **A. Hanya menautkan** ← rekomendasi | Superadmin membuat 4 akun ustadz di dashboard Supabase; Kelola User hanya **menautkan** dan mengelola baris `ustadz`/`santri` | Paling kecil, nol `service_role` | Santri mendaftar sendiri, jadi tidak ada 20 akun yang perlu dibuat manual. Ustadz cuma 4 orang, sekali seumur proyek |
| **B. Edge Function** | Fungsi Supabase memegang `service_role` sebagai secret; app memanggilnya | Sedang; tetap hosting statis | Perlu kalau superadmin harus bisa membuat akun tanpa membuka dashboard |
| **C. Server Node** | Matikan `ssr: false`, pakai server route | **Besar** | Membatalkan hosting statis dan menyulitkan PWA offline. **Tidak disarankan** |

**Opsi A cukup justru karena santri mendaftar sendiri.** Yang perlu dibuat manual
tinggal 4 akun ustadz, sekali. Naik ke B kalau pergantian asatidz jadi sering.

## 5. Hierarki peran: sebaiknya jangan dulu

Usulan menyebut "mengelola akun-akun role di bawahnya". Untuk 4 ustadz dan 20
santri, hierarki penuh adalah kerumitan yang belum dibayar manfaatnya.

**Disarankan:** hanya **superadmin** yang mengelola pengguna. Ustadz tidak
mengelola siapa pun. Tambahkan "ustadz boleh menyetujui santri di kelompoknya"
hanya kalau superadmin benar-benar jadi leher botol.

Tetap satu kolom, bukan tabel peran baru:

```sql
alter table ustadz add column superadmin boolean not null default false;
-- priv.peran() -> 'superadmin' | 'ustadz' | 'santri' | null
```

## 6. Perubahan skema yang dituntut

```sql
-- Klaim dari pendaftaran mandiri. Akun hidup hanya setelah disetujui.
create table pendaftaran (
  auth_id          uuid primary key references auth.users(id) on delete cascade,
  klaim_santri_id  bigint references santri(id),   -- klaim, BUKAN pemberian
  nama_diisi       text,
  status           text not null default 'menunggu'
                   check (status in ('menunggu','disetujui','ditolak')),
  diputuskan_oleh  bigint references ustadz(id),
  diputuskan_pada  timestamptz,
  dibuat_pada      timestamptz not null default now()
);
```

RPC pengganti `hubungkan_ustadz`:

| RPC | Pemanggil | Tugas |
|---|---|---|
| `daftar_sebagai_santri(klaim_santri_id, nama)` | santri baru | Menulis baris `pendaftaran`. **Tidak memberi akses apa pun** |
| `setujui_pendaftaran(auth_id)` | **superadmin** | Isi `santri.auth_id`; akses baru lahir di sini |
| `tolak_pendaftaran(auth_id, alasan)` | **superadmin** | Tandai ditolak |
| `tautkan_ustadz(ustadz_id, auth_id)` | **superadmin** | Menggantikan `hubungkan_ustadz` |

`hubungkan_ustadz` **dibuang**. Tautan Ust. Farizqi yang sudah ada tidak boleh
ikut hilang — migrasi hanya mencabut fungsinya, **tidak menyentuh**
`ustadz.auth_id`.

## 7. Pendaftaran terbuka: risikonya apa

Supaya santri bisa mendaftar sendiri, **Sign Ups harus tetap terbuka**. Yang
tersisa hanyalah orang asing membuat akun buta — nol akses, tapi menumpuk baris
sampah yang harus disaring superadmin.

**Belum perlu kode pendaftaran sekarang.** Tambahkan satu kode bersama per
angkatan kalau akun sampah benar-benar muncul.

Perlu ditegaskan supaya tidak tampak membatalkan keputusan sebelumnya: kode itu
**berbeda** dari kode klaim yang dulu dihapus. Yang dulu: rahasia **per orang**,
dibagikan satu-satu, dan **memberi identitas**. Yang ini: satu kode bersama,
disebut sekali di kelas, dan **tidak memberi apa pun** — persetujuan superadmin
tetap gerbangnya.

## 8. Keputusan yang menunggu

| # | Keputusan | Rekomendasi |
|---|---|---|
| **K8** | Bagaimana akun ustadz dibuat? | **Opsi A** — dashboard Supabase; Kelola User hanya menautkan |
| **K9** | Ustadz boleh mengelola santri? | **Tidak dulu.** Hanya superadmin |
| **K10** | Kode pendaftaran santri? | **Belum.** Tambahkan kalau akun sampah muncul |
| **K11** | Siapa superadmin pertama? | Satu nama, sekali lewat SQL: `update ustadz set superadmin = true where nama = '…'` |

## 9. Dampak ke daftar tugas

Mengubah tugas di `21-peran-dan-ujian-santri.md`:

| Tugas | Perubahan |
|---|---|
| **A1** | `ustadz.admin` → `ustadz.superadmin`; `priv.peran()` mengembalikan `'superadmin'` |
| **A4** | Diganti total: bukan "RPC kaitkan santri", tapi **4 RPC** di §6 + membuang `hubungkan_ustadz` |
| **A5** | Tambah kasus: akun terdaftar tapi **belum disetujui** juga harus buta total |
| **D1** | Layar masuk: **Daftar khusus santri** + pemilih nama sebagai klaim; ustadz hanya Masuk |
| **BARU H1** | Halaman **Kelola User** (superadmin): pendaftaran menunggu, setujui/tolak, tautkan ustadz, lihat siapa tertaut ke siapa |
| **BARU H2** | Check SQL: akun `menunggu` buta total; hanya superadmin bisa menyetujui; `hubungkan_ustadz` benar-benar hilang; **tautan Farizqi selamat** |

## 10. Yang harus dilakukan sekarang, sebelum ini jadi

Rancangan ini belum satu baris pun ditulis. Sementara itu **3 nama ustadz masih
menganggur dan `hubungkan_ustadz` masih hidup**. Tutup dulu dengan salah satu —
keduanya butuh satu menit:

- **Tutup Sign Ups** di dashboard Supabase, atau
- Suruh 3 ustadz sisanya mendaftar sekarang sehingga tidak ada nama menganggur

Catatan: begitu rancangan ini jadi, Sign Ups justru harus **dibuka lagi** supaya
santri bisa mendaftar — dan saat itu aman, karena akun baru tidak lagi bisa
menjadi siapa pun tanpa persetujuan.
