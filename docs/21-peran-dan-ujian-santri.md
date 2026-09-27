# 21 — Peran Pengguna & Ujian Santri (rencana)

Rencana untuk dua hal yang datang bersamaan: **peran pengguna** (admin / ustadz /
santri) dan **ujian daring yang dikerjakan santri sendiri di laptop**.

Dokumen ini rencana, belum implementasi. Daftar tugasnya ada di bagian akhir.

> Ini membalik asumsi yang tertulis di `01-system-overview.md` ("santri tidak
> punya akun dan tidak memegang perangkat") dan di `20-roadmap.md`. Dokumen itu
> wajib ikut diperbarui — tercantum sebagai tugas, bukan diserahkan pada ingatan.

---

## 1. Temuan yang menentukan segalanya

### 1a. Hanya 27 dari 41 anak-tangga bisa dinilai otomatis

Tangga yang ada dirancang untuk **lisan**: ustadz mendengar dan menimbang. Di
laptop tidak ada yang mendengar, jadi tiap langkah harus punya bentuk jawaban
yang bisa dinilai mesin. Setelah 41 langkah diklasifikasi:

| Bentuk | Jumlah | Contoh | Otomatis? |
|---|---|---|---|
| **pilihan** | 18 | "I'robnya apa?" → rofa'/nashob/jer/jazm | ✅ |
| **tunjuk_kata** | 9 | "Mubtada'nya mana?" → ketuk kata di ibarat | ✅ |
| **definisi** | 6 | "Apa pengertian mubtada'?" | ❌ hafalan terbuka |
| **alasan / produksi** | 8 | "Kenapa pakai tanda itu?" · "Ubahlah ke jamak!" | ❌ |

**`tunjuk_kata` adalah kunci kelayakannya.** Semua pertanyaan "…nya mana?"
bisa dijawab dengan mengetuk kata pada ibarat — persis interaksi `KetukKata`
yang sudah dipakai ustadz — dan kunci jawabannya cuma "kata yang mana". Tanpa
bentuk ini, hanya 18 langkah yang bisa diotomatiskan; dengan bentuk ini, 27.

### 1b. Konsekuensinya: ujian daring dan lisan mengukur hal yang berbeda

Yang tidak bisa diotomatiskan justru **"kenapa"** dan **"ubahlah"** — penalaran
dan produksi. Ujian daring mengukur **pengenalan**; ujian lisan mengukur
**penalaran**.

Ini bukan kelemahan, ini justifikasi kuat untuk tetap punya dua tes: persis
pemisahan "hafal vs paham" yang sejak awal jadi nilai jual diagnostik sistem ini.

**Aturan yang lahir dari sini: nilai daring dan nilai lisan TIDAK BOLEH
dirata-ratakan atau dibandingkan.** Keduanya ambang terpisah
(`kelas.ambang_online`, `kelas.ambang_offline`) — dan itu sudah benar sejak
`db/012`. Jangan pernah digabung jadi satu angka.

### 1c. BK 1 butuh bank soal baru

Soal BK 1 sekarang **lahir saat ustadz mengetuk kata** — himpunannya terbuka dan
tak terhingga. Kunci jawaban tidak mungkin disiapkan untuk kata sembarang.
Ujian daring BK 1 butuh **daftar lafad terkurasi** yang sudah berkunci. Itu
pekerjaan konten asatidz, bukan kode, dan jadi jalur kritis proyek ini.

### 1d. Integritas ujian: tiga lapis, dan batas jujurnya

Tiga kendali dipakai: **batas waktu ketat**, **soal diacak per santri**, dan
**layar penuh**. Ketiganya berharga, tapi kekuatannya sangat berbeda — dan itu
harus jelas sebelum nilainya dipercaya menggerbangi kenaikan kelas.

| Kendali | Kekuatan | Yang sebenarnya dilakukannya |
|---|---|---|
| **Batas waktu per soal** | ★★★ terkuat | Mencegah membuka kitab / bertanya — tidak ada waktunya |
| **Soal diacak per santri** | ★★ kuat | Mencegah menyalin jawaban tetangga |
| **Layar penuh** | ★ lemah | **Mendeteksi**, bukan mencegah |

#### Batas waktu: per SOAL, bukan hanya per ujian

Batas total (misal 30 menit untuk 20 soal) masih menyisakan celah: santri bisa
menghabiskan 5 menit mencari satu soal sulit lalu mengebut sisanya. Batas **per
soal** menutup celah itu sepenuhnya. Inilah kendali yang benar-benar bekerja.

**Konsekuensi skema:** server wajib mencatat **kapan tiap soal disajikan**
(`percobaan_soal.disajikan_pada`), karena tenggat dihitung dari sana — bukan dari
jam klien (P4). Tanpa kolom itu, batas per soal tidak bisa dipaksakan sama sekali;
santri cukup menghentikan JavaScript atau menggeser jam.

**Peringatan yang harus disampaikan ke asatidz:** tekanan waktu juga menghukum
santri yang **tahu tapi membaca Arab dengan lambat**. Untuk ujian ilmu alat, itu
kekeliruan pengukuran yang serius. Batasnya harus dikalibrasi dari data nyata,
bukan ditebak — dan kolom `detik` yang sudah dikumpulkan di sesi lisan adalah
sumber kalibrasinya. Simpan batasnya sebagai **data** (`ujian.detik_per_soal`),
bukan angka di dalam kode.

#### Soal diacak: harus berstrata, dan opsi ikut diacak

Pengacakan naif **merusak keadilan**: santri yang kebagian 8 nawasikh dinilai
jauh lebih keras daripada yang kebagian 8 ismiyah. Pelajaran ini sudah dibayar
di ujian lisan — `bagikanBK2` memecahkannya dengan pembagian merata per tipe,
dan aturan yang sama berlaku di sini.

Urutan **opsi jawaban** juga harus diacak per percobaan; kalau tidak, "jawabannya
selalu B" menyebar antar tetangga. Urutan itu **disimpan** di `percobaan_soal`
supaya memuat ulang halaman menampilkan urutan yang sama — kalau diacak ulang
tiap muat, santri bisa menyimpulkan sesuatu dari perubahannya.

#### Layar penuh: mendeteksi, bukan mencegah

Ini bagian yang harus jujur. **Browser selalu mengizinkan pengguna keluar dari
layar penuh** — Esc dan F11 tidak bisa dirampas oleh halaman web. Itu jaminan
keamanan browser, bukan kekurangan implementasi. Jadi layar penuh tidak pernah
bisa menahan siapa pun.

Yang bisa dilakukan: mencatat `fullscreenchange`, `visibilitychange`, dan `blur`
sebagai peristiwa untuk **ditinjau ustadz**. Nilainya ada pada jejaknya dan pada
efek psikologisnya — bukan pada pencegahannya.

**Jangan pernah menggugurkan ujian otomatis karena keluar layar penuh.**
Peristiwa itu juga muncul karena sebab tak bersalah: Esc kepencet, notifikasi
sistem, alt-tab tak sengaja. Menggugurkan otomatis akan menghukum santri yang
tidak bersalah. Catat, tandai, serahkan ke ustadz (sejalan R10).

Dan lubang terbesarnya tidak akan pernah terlihat oleh layar penuh: **HP atau
kitab terbuka di samping laptop.** Untuk itu tidak ada kendali perangkat lunak
apa pun — di browser mana pun, dengan cara apa pun.

#### Konsekuensi: percobaan harus bisa dibatalkan

Batas waktu per soal + jaringan yang putus = soal terlewat bukan karena tidak
bisa. Server **tidak mungkin** membedakan "tenggat lewat" dari "jaringan mati".

Jadi `percobaan` butuh `dibatalkan_oleh` + `alasan`, dan ustadz harus bisa
menggugurkan satu percobaan supaya santri mengulang. Tanpa itu, satu gangguan
teknis jadi nilai buruk yang permanen — dan di ujian yang menggerbangi kenaikan
kelas, itu tidak bisa diterima.

#### Kesimpulan yang tidak berubah

Ketiga kendali ini menaikkan biaya kecurangan santai secara nyata, dan itu
berharga. Tapi tidak satu pun menutup HP di samping laptop. **Pengawasan tetap
kendali yang sebenarnya**, dan keputusan K1 tetap harus diambil sebelum nilai
daring dipakai menggerbangi kenaikan (R22).

## 2. Peran

Tiga peran. Tidak ada yang keempat sampai benar-benar dibutuhkan.

| Peran | Dari mana | Bisa apa |
|---|---|---|
| **admin** | baris `ustadz` dengan `admin = true` | Semua milik ustadz + master data + buat akun santri + jadwalkan ujian |
| **ustadz** | punya baris di `ustadz` | Menilai, melihat diagnostik, memutuskan kenaikan |
| **santri** | punya baris di `santri` dengan `auth_id` terisi | Mengerjakan ujian miliknya, melihat hasilnya sendiri |

**Tanpa tabel peran baru.** Peran diturunkan dari tabel yang sudah ada; admin
cuma satu kolom boolean. Di pesantren, admin memang seorang ustadz (kepala
madrasah), jadi tabel terpisah hanya akan menduplikasi orang yang sama.

```sql
-- SECURITY DEFINER, di schema priv (tidak diekspos PostgREST)
priv.peran() -> 'admin' | 'ustadz' | 'santri' | null
```

> ⚠️ **Bagian ini digantikan.** `hubungkan_ustadz` sedang ditinjau: akun ustadz
> akan dibuat superadmin lewat layar Kelola User, dan santri mendaftar sendiri
> lalu **disetujui**. Rancangan penggantinya di
> [`22-kelola-user.md`](22-kelola-user.md), termasuk perubahan tugas A1/A4/A5/D1.

### Asimetri yang wajib: santri TIDAK memilih namanya sendiri

Ustadz boleh memilih namanya dari daftar — jumlahnya empat, dan mereka saling
kenal. **Santri tidak boleh.** Dua puluh santri memilih sendiri berarti siapa
pun bisa mengaku siapa pun, dan nilai ujian jadi tak bermakna.

Akun santri **dibuat dan dikaitkan oleh admin**. Konsekuensinya: **CRUD master
data (roadmap #1) jadi prasyarat keras**, bukan lagi sekadar prioritas.

### Kabar baik soal RLS

23 dari 24 policy sekarang bergantung pada `priv.is_ustadz()`, yang bernilai
`false` untuk akun santri. Artinya begitu santri punya akun, mereka melihat
**nol baris** dari hampir semua tabel — defaultnya **gagal-tertutup**, bukan
terbuka. Setiap akses santri harus ditambahkan dengan sengaja.

Satu policy yang benar-benar longgar dan harus diperketat:
`create policy baca on ustadz for select to authenticated using (true)` —
ini membuka `auth_id` semua ustadz kepada akun mana pun. Batasi kolomnya lewat
view atau perketat policy-nya.

---

## 3. Prinsip rancangan ujian santri

### P1. Peserta tidak pernah SELECT tabel materi

Seluruh isi ujian — teks soal, teks pertanyaan, pilihan jawaban — dialirkan
lewat **RPC**, bukan lewat query tabel. `soal`, `langkah`, `ibarat`,
`opsi_jawaban` tetap tertutup untuk santri.

Satu pintu jauh lebih mudah diaudit daripada belasan policy, dan sekaligus
mencegah santri membaca bank soal sebelum ujian.

### P2. Kunci jawaban dijaga dua lapis

RLS bersifat baris, tidak bisa menyembunyikan **kolom**. Jadi:

1. `opsi_jawaban` — RLS menolak santri sepenuhnya.
2. `revoke select (benar) on opsi_jawaban from authenticated` — proteksi tingkat
   kolom, supaya kesalahan policy pun tidak membocorkan kunci.
3. RPC pengirim soal hanya menyeleksi `id, teks` — **`benar` tidak pernah
   meninggalkan server**.

Penilaian dihitung di server, dari `jawaban_ujian` di-join ke `opsi_jawaban.benar`.

### P3. Ujian santri TIDAK memakai antrean offline

Ini kebalikan sadar dari aplikasi ustadz.

Aplikasi ustadz offline-first karena **operatornya dipercaya** dan sinyal kelas
buruk. Ujian santri **tidak boleh** menyimpan jawaban di localStorage: itu
memberi peserta akses tulis ke datanya sendiri sebelum terkirim.

Jawaban dikirim langsung ke server, satu panggilan per jawaban. Kalau jaringan
putus, percobaan **berhenti dan bisa dilanjutkan** — server sudah memegang semua
jawaban sejauh itu. Lebih aman sekaligus lebih sederhana.

### P4. Waktu selalu waktu server

`mulai_pada`, `selesai_pada`, dan batas waktu dihitung di server. Jam klien tidak
pernah dipercaya. Hitungan mundur di layar hanya hiasan; yang menutup percobaan
adalah server.

### P5. Nilai tetap tidak disimpan (R1)

Ini ternyata **keuntungan keamanan**: santri tidak bisa mengubah nilai yang tidak
ada. Yang tersimpan hanya pilihan jawaban; nilai dihitung di view.

### P6. Satu percobaan per santri per ujian, dipaksa server

`unique (ujian_id, santri_id)` pada `percobaan`. Soal dibagikan **saat percobaan
dimulai** dan dicatat di `percobaan_soal` — jadi memuat ulang halaman tidak
memberi soal baru yang lebih mudah.

---

## 4. Model data yang diusulkan

Tabel baru, terpisah dari `sesi`/`penilaian`/`jawaban`. **Tidak digabung**:
`sesi.ustadz_id` NOT NULL dan model integritasnya berbeda jauh
(disaksikan ustadz vs dikerjakan sendiri). Menggabungkan berarti melonggarkan
constraint yang ada dan mencampur dua aturan keamanan.

```sql
-- Bentuk jawaban yang bisa dinilai mesin
alter table langkah add column bentuk text
  check (bentuk in ('pilihan','tunjuk_kata','definisi','produksi'));
-- 'definisi' dan 'produksi' tidak masuk ujian daring.

-- Pilihan jawaban. Daftar opsi melekat pada LANGKAH (mis. 4 opsi i'rob dipakai
-- semua soal); yang benar melekat pada (soal, langkah).
create table opsi (
  id bigint primary key generated always as identity,
  langkah_id bigint not null references langkah(id),
  teks text not null, urutan int not null
);

create table kunci (
  soal_id    bigint not null references soal(id),
  langkah_id bigint not null references langkah(id),
  opsi_id    bigint references opsi(id),        -- utk bentuk 'pilihan'
  kata       text,                              -- utk bentuk 'tunjuk_kata'
  diverifikasi_oleh bigint references ustadz(id),  -- null = draf, belum sah
  primary key (soal_id, langkah_id)
);
-- Kunci tanpa `diverifikasi_oleh` TIDAK BOLEH dipakai ujian (R10: AI menyiapkan,
-- ustadz memutuskan).

create table ujian (
  id bigint primary key generated always as identity,
  kelas_kode text not null references kelas(kode),
  nama text not null,
  buka_pada timestamptz not null, tutup_pada timestamptz not null,
  durasi_menit int not null,
  detik_per_soal int,                      -- batas per soal; null = tanpa batas
  jml_soal int not null,
  diawasi boolean not null default true,   -- jujur dicatat; lihat 1d
  wajib_layar_penuh boolean not null default true,
  dibuat_oleh bigint not null references ustadz(id)
);
-- `detik_per_soal` adalah DATA, bukan angka di kode: harus dikalibrasi dari
-- `jawaban.detik` sesi lisan, bukan ditebak. Lihat 1d.

create table percobaan (
  id bigint primary key generated always as identity,
  ujian_id bigint not null references ujian(id),
  santri_id bigint not null references santri(id),
  mulai_pada timestamptz not null default now(),
  selesai_pada timestamptz,
  -- Server tidak mungkin membedakan "tenggat lewat" dari "jaringan mati", jadi
  -- ustadz harus bisa menggugurkan percobaan supaya santri mengulang.
  dibatalkan_oleh bigint references ustadz(id),
  alasan_batal text,
  unique (ujian_id, santri_id)             -- satu percobaan, dipaksa server
);

create table percobaan_soal (
  id bigint primary key generated always as identity,
  percobaan_id bigint not null references percobaan(id) on delete cascade,
  soal_id bigint not null references soal(id),
  langkah_id bigint not null references langkah(id),
  urutan int not null,
  -- Tenggat per soal dihitung dari SINI, bukan dari jam klien (P4). Tanpa kolom
  -- ini batas waktu per soal tidak bisa dipaksakan sama sekali.
  disajikan_pada timestamptz,
  -- Urutan opsi diacak per percobaan lalu DISIMPAN, supaya memuat ulang halaman
  -- menampilkan urutan yang sama. Kalau diacak tiap muat, perubahannya sendiri
  -- jadi petunjuk.
  urutan_opsi bigint[],
  unique (percobaan_id, urutan)
);

create table jawaban_ujian (
  percobaan_soal_id bigint primary key references percobaan_soal(id) on delete cascade,
  opsi_id bigint references opsi(id),
  kata text,
  detik numeric,
  dijawab_pada timestamptz not null default now()
);
-- primary key pada percobaan_soal_id = satu jawaban per soal.
-- Tanpa UPDATE/DELETE untuk santri: jawaban tidak bisa diubah setelah dikirim.

-- Jejak peristiwa layar penuh / pindah tab / kehilangan fokus.
-- HANYA untuk ditinjau ustadz. TIDAK PERNAH menggugurkan otomatis (1d).
create table peristiwa_percobaan (
  id bigint primary key generated always as identity,
  percobaan_id bigint not null references percobaan(id) on delete cascade,
  jenis text not null check (jenis in ('keluar_layar_penuh','masuk_layar_penuh','tab_tersembunyi','tab_kembali','fokus_hilang')),
  terjadi_pada timestamptz not null default now()
);
```

RPC (semuanya memvalidasi kepemilikan percobaan + jendela waktu):

| RPC | Tugas |
|---|---|
| `mulai_percobaan(ujian_id)` | Buat percobaan, bagikan soal berkunci-terverifikasi secara acak, kembalikan id |
| `soal_percobaan(percobaan_id, urutan)` | Kirim satu soal + pilihan **tanpa `benar`** |
| `jawab_percobaan(percobaan_soal_id, opsi_id, kata, detik)` | Simpan satu jawaban, tolak kalau sudah dijawab / lewat waktu |
| `sudahi_percobaan(percobaan_id)` | Tandai selesai |
| `catat_peristiwa(percobaan_id, jenis)` | Rekam keluar layar penuh / pindah tab, untuk ditinjau |
| `batalkan_percobaan(percobaan_id, alasan)` | **Ustadz** menggugurkan percobaan yang terganggu teknis |

View: `v_nilai_ujian` (per percobaan) dan `v_nilai_ujian_santri`.

---

## 5. Keputusan yang harus diambil pesantren

Diurutkan dari yang paling menentukan. Ini bukan keputusan teknis.

| # | Keputusan | Rekomendasi | Kalau salah pilih |
|---|---|---|---|
| **K1** | Ujian daring **diawasi** atau di kamar masing-masing? | **Diawasi** — satu ruang, waktu terjadwal, ustadz hadir | Tak diawasi = nilai tidak layak menggerbangi kenaikan; turunkan jadi latihan mandiri. Batas waktu + layar penuh + soal acak menaikkan biaya kecurangan santai, tapi tidak satu pun menutup HP di samping laptop (§1d) |
| **K2** | Nilai mana yang jadi `nilai_online` penggerbang kenaikan? | **Ujian santri** jadi `nilai_online`; leger lisan ustadz mengisi `nilai_offline` **otomatis**, tidak lagi diketik tangan | Kalau tetap pakai sesi ustadz sebagai `nilai_online`, ujian santri tidak berpengaruh apa pun pada kenaikan |
| **K3** | Siapa memverifikasi kunci jawaban, dan kapan? | Asatidz penyusun soal; **20 soal dulu**, cukup untuk satu ujian | Menunggu 360 kunci selesai = fitur ini tidak pernah dirilis |
| **K4** | Bagaimana santri dapat akun? | Admin membuat, email berpola `nama@santri.<pesantren>`, kata sandi awal dibagikan lisan | Santri memilih nama sendiri = identitas tak bermakna |
| **K5** | Santri boleh melihat nilainya sendiri? | Boleh, **setelah jendela ujian tutup** | Kalau boleh saat ujian berjalan, jawaban bisa dicoba-coba |
| **K6** | Langkah `definisi` (6 langkah) dijadikan pilihan ganda? | **Jangan dulu** — itu mengubah ujian pemahaman jadi kuis hafalan | Boleh ditinjau ulang setelah satu siklus |
| **K7** | Berapa `detik_per_soal`? | **Jangan ditebak.** Set `null` dulu (tanpa batas per soal), kalibrasi dari `jawaban.detik` sesi lisan setelah ada data nyata — usulkan sekitar persentil 90 | Terlalu ketat = menghukum santri yang tahu tapi membaca Arab lambat; terlalu longgar = ada waktu membuka kitab |

---

## 6. Biaya nyata

| Pekerjaan | Sifat | Perkiraan |
|---|---|---|
| Peran + audit ulang seluruh RLS | Kode, teliti | Terbesar dari sisi risiko |
| Mesin ujian (tabel + 4 RPC + view) | Kode | Sedang, lurus |
| UI santri | Kode | Kecil — 3 halaman |
| **Kunci jawaban** | **Konten asatidz** | **Jalur kritis**: 20 soal × ~6 langkah = ~120 kunci untuk ujian pertama; ~360 kalau seluruh bank BK 2 |
| Bank lafad BK 1 terkurasi | Konten asatidz | Belum ada sama sekali |

Jalur kritisnya **bukan kode**. Tanpa kunci terverifikasi, mesin ujiannya
menganggur. Karena itu Fase B dikerjakan paralel sejak awal, dan sengaja
dibatasi 20 soal dulu.

---

## 7. Urutan pengerjaan

```
A. Peran + RLS          ← prasyarat keras, tidak bisa dilewati
B. Bank berkunci        ← paralel; jalur kritis; konten asatidz
C. Mesin ujian          ← butuh A dan B
D. UI santri            ← butuh C
E. UI ustadz/admin      ← butuh C
F. Integrasi kenaikan   ← butuh D+E dan keputusan K2
G. Dokumen + uji asap   ← terakhir, tapi bukan opsional
```

Aturan gerbang tetap berlaku (R15): `npm test`, `npm run typecheck`,
`npm run build`, plus check SQL yang relevan. Setiap RPC baru wajib diuji lewat
**panggilan sungguhan** (R5), dan setiap policy baru wajib punya check yang
membuktikan santri tidak bisa melihat milik orang lain.

---

## 8. Aturan baru yang lahir dari rencana ini

Diusulkan masuk `00-project-rules.md` saat implementasi dimulai:

- **R18.** Peserta ujian tidak pernah `SELECT` tabel materi. Seluruh isi ujian
  lewat RPC. Satu pintu, bisa diaudit.
- **R19.** Kunci jawaban dijaga RLS **dan** proteksi kolom, dan tidak pernah
  meninggalkan server. Kunci tanpa verifikasi ustadz tidak boleh dipakai ujian.
- **R20.** Data yang ditulis peserta tidak pernah melewati localStorage.
  Offline-first hanya untuk aplikasi ustadz, di mana operatornya dipercaya.
- **R21.** Nilai daring dan nilai lisan tidak pernah dirata-ratakan atau
  dibandingkan — keduanya mengukur hal yang berbeda (pengenalan vs penalaran).
- **R22.** Integritas ujian bersandar pada pengawasan, bukan perangkat lunak.
  Jangan pernah menjanjikan yang tidak bisa ditepati kode.
