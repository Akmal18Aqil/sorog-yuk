# DESAIN.md: Sistem Desain Sorogan Digital

Spesifikasi yang bisa langsung dikerjakan. Setiap nilai warna di bawah sudah
dihitung dengan `contrast-check.py` (skill `antislop-human`), setiap breakpoint
ditempatkan di titik konten berhenti bekerja, bukan di daftar lebar ponsel.

Filter yang dipakai: `C:\Users\pondo\.claude\skills\antislop\` (core, `ui`,
`human`, `layoutmobile`). Arah visual: dokumen ini, disetujui pemilik proyek.

Untuk mengulang sendiri perhitungannya:

```
python C:\Users\pondo\.claude\skills\antislop-human\contrast-check.py "#25543f" "#fffdf8"
```

---

## 1. Design Read

> Membaca ini sebagai: **alat kerja internal pesantren** untuk penguji yang
> mencatat leger sambil berdiri di depan Santri, dengan bahasa visual *kertas
> dan tinta*, dial **ENERGY 1 / RHYTHM 1 / MOTION 1**.

Alasan dial, bukan selera:

- **ENERGY 1.** Ujian berjalan di depan orang. Animasi, gradient besar, dan
  hero besar cuma memperlambat. Layar harus diam dan melayani pencatatan.
- **RHYTHM 1.** Ini aplikasi alat, bukan landing page. Satu pola susunan yang
  konsisten lebih cepat dipelajari orang yang memakainya dua kali setahun.
- **MOTION 1.** Hanya transisi state. Tanpa loop, tanpa scroll-reveal. Gerak
  yang tidak menjelaskan sesuatu hanya menambah beban.

### Karakter yang harus terasa

- **Kertas, bukan dashboard.** Permukaan datar dengan garis rambut, bukan kartu
  yang melayang. Alasannya: leger kertas tidak punya bayangan, dan aplikasi ini
  harus terasa seperti sambungan dari kertas, bukan aplikasi baru.
- **Tinta, bukan neon.** Hijau tua `#25543f` sudah ada di `nuxt.config.ts` dan
  manifest PWA, jadi identitasnya gratis. Hanya satu warna aksen (amber) untuk
  hal yang benar-benar perlu penekanan: status `dibantu`.
- **Satu fokus per layar.** Di layar uji, fokusnya lafad Arab. Di layar admin,
  fokusnya baris pertama tabel. Sisanya mundur.

---

## 2. Warna

Tiga warna inti (netral tidak dihitung) plus satu aksen, sesuai `R-29`:

| Peran | Token | Light | Dark |
|---|---|---|---|
| Tinta (teks utama) | `--tinta` | `#1b2420` | `#e8ece9` |
| Tinta redup (label, meta) | `--tinta-2` | `#5c6b64` | `#9aa39f` |
| Kertas (latar halaman) | `--kertas` | `#f7f5ef` | `#16191a` |
| Permukaan (kartu, sheet) | `--permukaan` | `#fffdf8` | `#1e2223` |
| Garis rambut (pemisah) | `--garis` | `#dcd8cd` | `#2c3133` |
| Garis kontrol (border input) | `--garis-kontrol` | `#8f8874` | `#6f7a7c` |
| Hijau tinta (aksen utama) | `--hijau` | `#25543f` | `#7d9b8a` |
| Hijau pekat (hover) | `--hijau-pekat` | `#1e4432` | `#a3c0ae` |
| Hijau muda (latar terpilih) | `--hijau-muda` | `#e8efe9` | `#1b2721` |

Status nilai, hanya tiga, dipetakan ke nama yang sudah dipakai kode
(`--benar`, `--dibantu`, `--salah`):

| Status | Light (teks) | Light (latar) | Dark (teks) | Dark (latar) |
|---|---|---|---|---|
| `benar` | `#1f6b45` | `#eef4f0` | `#8fbf9f` | `#1b2721` |
| `dibantu` | `#8a5a12` | `#faf1de` | `#d9a441` | `#2a2312` |
| `salah` | `#a33227` | `#faf0ee` | `#d98b7f` | `#2b1c1a` |

Aksen amber hanya boleh muncul pada `dibantu`. Hijau hanya untuk aksi utama dan
status `benar`. Merah hanya untuk `salah` dan penghapusan. Tanpa kecuali, warna
berhenti jadi informasi dan mulai jadi hiasan.

### Hasil perhitungan kontras

Dihitung dengan `python contrast-check.py`. Ambang: 4.5:1 teks normal, 3:1
teks besar dan batas komponen (WCAG 1.4.11).

| Pasangan | Rasio | Status |
|---|---|---|
| `#1b2420` di `#f7f5ef` | 14.59 | PASS |
| `#1b2420` di `#fffdf8` | 15.65 | PASS |
| `#5c6b64` di `#f7f5ef` | 5.15 | PASS |
| `#5c6b64` di `#fffdf8` | 5.52 | PASS |
| `#25543f` di `#f7f5ef` | 7.96 | PASS |
| `#25543f` di `#fffdf8` | 8.54 | PASS |
| `#ffffff` di `#25543f` | 8.68 | PASS |
| `#ffffff` di `#1e4432` | 10.89 | PASS |
| `#1f6b45` di `#eef4f0` | 5.80 | PASS |
| `#8a5a12` di `#faf1de` | 5.27 | PASS |
| `#a33227` di `#faf0ee` | 6.17 | PASS |
| `#8f8874` di `#fffdf8` | 3.48 | PASS (batas, bukan teks) |
| `#e8ece9` di `#16191a` | 14.82 | PASS |
| `#e8ece9` di `#1e2223` | 9.89 | PASS |
| `#9aa39f` di `#1e2223` | 6.20 | PASS |
| `#7d9b8a` di `#1e2223` | 5.30 | PASS |
| `#8fbf9f` di `#1b2721` | 7.45 | PASS |
| `#d9a441` di `#2a2312` | 6.93 | PASS |
| `#d98b7f` di `#2b1c1a` | 6.19 | PASS |
| `#6f7a7c` di `#1e2223` | 3.63 | PASS (batas) |

Dua hasil yang perlu dicatat, keduanya disengaja:

- `--garis-kontrol` gelap harus `#6f7a7c` (3.63:1), bukan `#5c6668` yang hanya
  2.72:1 dan gagal 3:1. Dua nilai ini tidak boleh disamakan.
- `--garis` `#dcd8cd` hanya 1.31:1 dan itu memang disengaja: garis rambut
  hanya pemisah dekoratif, bukan batas komponen. Batas kontrol selalu
  memakai `--garis-kontrol`.

### Warna yang dilarang

- Gradient biru-ungu, biru-sian, ungu-pink, dan seluruh keluarga rainbow.
  `--primary-light: #e8f0ec` di `main.css` lama adalah sisa gradient yang
  tidak pernah jadi warna brand. Dihapus, bukan dipoles.
- Neon di mode gelap. Mode gelap untuk dipakai di ruang ujian dengan proyektor
  atau HP entry, bukan untuk terlihat "keren".
- Bayangan sebagai identitas. Bayangan hanya untuk satu lapis: dialog.


---

## 3. Tipografi

Satu family untuk UI, satu untuk Arab. Tidak ada font web, tidak ada unduhan
jaringan: PWA harus tetap terbuka di lapangan yang sinyalnya hilang.

```css
--font-ui: system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;
--font-arab: 'Scheherazade New', 'Amiri', 'Noto Naskh Arabic', 'Traditional Arabic', serif;
```

Alasan memilih `system-ui` untuk UI: aplikasi ini dipakai dua kali setahun,
dan unduhan font 200 kB akan menunda layar pertama di HP mahal. Huruf sistem
tidak perlu di-cache dan tidak pernah gagal render karena `font-display`
menyala di tengah bacaan Arab. Ini pilihan teknis, bukan soal selera.

Alasan memilih naskh untuk Arab: bentuk huruf harus sama dengan yang dipakai
Santri hafal di mushaf, jadi naskh di sini soal akurasi, bukan soal gaya.

### Skala

Fluid antara 360px dan 1280px memakai `clamp`. Di bawah 360px (ponsel lama di
kampus) nilai mengunci ke batas paling kecil, tidak menyusut lagi.

| Token | Nilai | Pemakaian |
|---|---|---|
| `--t-2xs` | `11px` | Waktu jawab pada satu langkah |
| `--t-xs` | `12px` | Label tabel, caption |
| `--t-sm` | `13px` | Teks sekunder, sub-teks baris |
| `--t-base` | `15px` | Body, daftar, input |
| `--t-md` | `17px` | Judul kartu, nama Santri |
| `--t-lg` | `20px` | Judul seksi |
| `--t-xl` | `24px` | Judul halaman |
| `--t-arab` | `clamp(28px, 7vw, 40px)` | Lafadz dalam satu baris |
| `--t-arab-besar` | `clamp(34px, 9vw, 56px)` | Lafadz di layar ketuk kata |

Badan teks 15px, bukan 16px. Alasannya teknis: 15px menambah jumlah karakter
per baris di 360px, dan leger adalah tabel yang harus muat. Di desktop
`--t-base` dinaikkan ke 16px lewat media query, karena di situ jarak baca
bukan masalah.

### Teks Arab

```css
.arab {
  font-family: var(--font-arab);
  direction: rtl;
  text-align: right;
  line-height: 2.0;
  font-size: var(--t-arab);
  -webkit-font-smoothing: antialiased;
  text-rendering: optimizeLegibility;
}
```

Jangan pakai `text-align: center` untuk teks Arab. Naskh dibaca dari kanan,
kolom rata-tengah membuat awal baris terasa meleset. Rata kanan, kecuali satu
kata yang berdiri sendiri di tengah kartu.

### Angka

Angka leger wajib `font-variant-numeric: tabular-nums`. Alasannya: kolom
nilai harus sejajar vertikal supaya antar Santri bisa dibandingkan tanpa
membaca, persis seperti kolom di leger kertas.

---

## 4. Ruang, radius, elevasi

### Ruang

Skala 4px, tanpa angka ganjil. Angka ganjil tidak ada gunanya kecuali jadi
sumber kebocoran satu piksel saat ada tangkapan layar.

```
--s1: 4px   --s2: 8px   --s3: 12px  --s4: 16px  --s5: 20px
--s6: 24px  --s8: 32px  --s10: 40px --s12: 48px
```

Radius dipakai sebagai alat hierarki, bukan dekorasi (R-11). Empat nilai, dan
setiap nilai punya satu tugas:

| Nilai | Dipakai di | Alasan |
|---|---|---|
| `--r2` 8px | input, tombol, baris filter | Rasio kecil untuk kontrol kecil |
| `--r3` 12px | kartu, list item, dialog | Permukaan utama |
| `--r4` 16px | sheet dari bawah, panel | Satu-satunya bentuk besar, biar tidak saing dengan kartu |
| `--r-full` | chip, avatar, meter | Bentuk memang bulat di dunia nyata |

Tidak ada tombol pil, kartu pil, atau badge pil. Kalau semuanya bulat, bentuk
tidak lagi membedakan input dari kartu.

### Elevasi

Satu token bayangan, untuk dialog saja. Kartu, sheet, dan baris navigasi tidak
punya bayangan: mereka dipisahkan oleh garis rambut, seperti garis di kertas.
Satu-satunya alasan bayangan dipakai: lapisan yang benar-benar menutupi isi
di bawahnya.

```css
--bayang-1: 0 6px 20px rgba(27, 36, 32, .14);
```

Di mode gelap, bayangan hilang dan dialog dibedakan oleh garis `--garis-kontrol`
ditambah latar yang lebih terang. Bayangan hitam di atas permukaan gelap tidak
terlihat, hanya kotor.

---

## 5. Layout: dua shell, bukan satu layout yang diperkecil

Ini inti dari permintaan "desktop dan mobile untuk semua ukuran layar".
Versi lama mengunci `max-width: 640px` di semua ukuran, jadi di monitor 27 inci
aplikasi ini terlihat seperti HP yang diperbesar. Itu bukan desain responsif,
itu layout yang belum pernah dirancang ulang.

Prinsipnya (`antislop-layoutmobile`): **mobile adalah layout yang berbeda, bukan
layout desktop yang dikecilkan.** Ada dua shell dengan cara berbeda menampilkan
navigasi, kontainer, dan tabel.

### Shell A: shell Ponsel (bawaan, `< 900px`)

```
┌──────────────────────────┐
│ Judul        [aksi]     │  header, menempel di atas, 56px
├──────────────────────────┤
│                          │
│   Konten satu kolom      │  max 640px, padding 16px
│   kartu demi kartu       │  padding bawah 84px
│                          │  (ruang untuk nav)
│                          │
├──────────────────────────┤
│  Beranda  Uji  Hasil  Akun│  bottom nav, 64px + safe-area
└──────────────────────────┘
```

Alasan navigasi bawah di shell ini: tangan sudah memegang HP dengan ibu jari
dekat tepi bawah. Menu di atas berarti meregangkan tangan. Batas 900px, bukan
640px: antara 640 dan 900 satu kartu masih muat nyaman, dan memindahkan
navigasi terlalu awal membuatnya terasa jauh dari konten yang dibacanya.

### Shell B: Meja Kerja (>= 900px)

```
┌──────────┬───────────────────────────────┐
│          │ Judul halaman        [aksi]  │
│  SOROGAN │──────────────────────────────│
│          │                               │
│ Beranda  │  Konten, max 1100px          │
│ Uji      │  Tabel leger boleh lebar     │
│ Hasil    │  penuh, tidak digulir         │
│ Santri   │  horizontal                  │
│ ──────── │                               │
│ Kelas    │                               │
│ Kitab    │                               │
│ Soal     │                               │
│ Langkah  │                               │
└──────────┴───────────────────────────────┘
   216px tetap           mengisi sisa ruang
```

Alasan navigasi pindah ke kiri: di 900px ke atas, dokumen ini dibaca bukan
dibidik. Sisi kiri adalah tempat mata sudah berhenti, dan sidebar membuat
ruang konten penuh untuk tabel leger yang lebarnya 13 kolom.

### Titik di mana konten benar-benar berubah

Breakpoint di sini bukan "ukuran iPhone". Setiap angka dipilih karena di titik
itu komponen tertentu berhenti bekerja, dan alasannya ditulis supaya bisa
diuji ulang.

| Token | Ukuran | Apa yang berubah dan kenapa |
|---|---|---|
| `--b1` | 480px | Baris tombol mulai bertumpuk. Dua tombol "Batal" dan "Buat Akun" di 360px hanya tersisa sekitar 164px masing-masing, di bawah lebar label yang nyaman. Di sini tombol menjadi vertikal dan penuh. |
| `--b2` | 700px | Grid statistik 4 kolom jadi 2 kolom. Empat kartu 160px di 700px masih muat, tapi `StatCard` berisi label "Kelompok" mulai terpotong dua baris. |
| `--b3` | 900px | Shell berubah ke Meja Kerja. Ini batas paling penting: di bawah 900px navigasi bawah masih dalam jangkauan tangan, di atas tidak. |
| `--b4` | 1100px | Konten berhenti melebar, sidebar tetap 216px. Lebar baca di atas 1100px untuk daftar nama dan tabel angka sudah tidak nyaman, jadi sisanya jadi ruang kosong yang disengaja. |

Rentang yang harus benar-benar diuji, bukan diasumsikan:

- 320px: HP lama, masih dipakai di luar kota
- 360px: Android paling umum
- 414px: iPhone yang lebih lebar
- 600px: HP dalam mode landscape
- 768px: tablet dengan orientation tegak
- 1024px: tablet landscape dan iPad
- 1280px: laptop standar
- 1920px: monitor ruang ustadz
- 2560px: monitor besar, termasuk beberapa yang pakai scaling 125%

### Dua shell, satu sistem token

Semua token warna, ruang, radius, dan font dipakai identik di kedua shell.
Yang berubah hanya kerangka: `display` kerangka, `max-width` konten, dan
posisi navigasi. Tidak ada warna khusus desktop. Kalau nanti terlihat perlu
warna khusus desktop, itu tanda layoutnya salah, bukan tanda themenya.

### Grid konten

```css
/* Shell A: satu kolom, tanpa pilihan. */
.isi {
  width: 100%;
  max-width: 640px;
  margin-inline: auto;
  padding: var(--s4);
  padding-bottom: calc(84px + env(safe-area-inset-bottom));
}

/* Shell B: konten boleh selebar jendela, tapi tidak lebih dari 1100px. */
@media (min-width: 900px) {
  .isi {
    max-width: 1100px;
    padding: var(--s6);
    padding-bottom: var(--s8);
  }
  :root { --t-base: 16px; }
}
```

Ruang bawah shell A bukan pelengkap: 84px-nya persis tinggi navigasi bawah
(64px) ditambah 20px. Tanpa itu, baris terakhir daftar atau tombol "Simpan"
tertutup navigasi dan tidak bisa disentuh. Ini yang harus diuji, bukan
diasumsikan.

---

## 6. Komponen

### 6.1 Navigasi

Navigasi bawah (shell A) dan sidebar (shell B) menampilkan **daftar item yang
sama**, bukan dua daftar terpisah. Satu sumber, dua tampilan. Kalau nanti
tidak sinkron, itu bug navigasi, bukan soal tampilan.

```css
.nav-item {
  display: flex;
  align-items: center;
  gap: var(--s3);
  min-height: 48px;          /* di bawah 48px target sentuh gagal */
  padding: var(--s3) var(--s4);
  color: var(--tinta-2);
  text-decoration: none;
  border-radius: var(--r2);
}
.nav-item[aria-current="page"] {
  color: var(--hijau);
  background: var(--hijau-muda);
  font-weight: 600;
}
```

Aktif ditandai oleh **warna, latar, dan berat huruf** sekaligus. Warna
saja tidak cukup: orang dengan buta warna tidak akan melihat bedanya.

Navigasi bawah tidak memakai `backdrop-filter`. Alasannya, `antislop` R-10:
blur menghapus tekstur dan menjadikan semua permukaan satu lapis frosted, lalu
tidak ada yang jadi foreground. Sebenarnya `backdrop-filter` di proyek ini
cuma ada di satu tempat, yaitu `.overlay` (latar dialog), dan itu masih di
batas dosis: satu elemen. Yang berubah hanya `bottom-nav`, yang tidak pernah
pakai blur dan sekarang digariskan.

Ikon di navigasi juga dihapus, bukan diganti set ikon baru. Alasannya: label
saja sudah cukup untuk lima tujuan, dan emoji di setiap platform tampil
berbeda. Mengganti emoji dengan SVG berarti menggambar dan memeriksa setiap
ikon, sementara teks tidak pernah salah render. Kalau nanti butuh ikon, itu
penambahan yang harus dibuktikan dulu, bukan sekarang.

```css
.nav-bawah {
  position: fixed;
  inset-inline: 0;
  bottom: 0;
  display: grid;
  grid-auto-flow: column;
  grid-auto-columns: 1fr;
  background: var(--permukaan);
  border-top: 1px solid var(--garis);
  padding-bottom: env(safe-area-inset-bottom);
}
```

Hamburger telanjang dilarang (`antislop-layoutmobile`): kalau ada menu
hamburger tanpa label, orang tidak tahu isinya apa. Di shell B tidak ada
hamburger sama sekali, karena sidebar selalu terlihat.

### 6.2 Tombol

Tiga jenis, tidak lebih. Setiap jenis punya satu tugas yang tidak bisa
diganti jenis lain.

| Jenis | Untuk | Bentuk |
|---|---|---|
| `utama` | aksi utama layar: "Mulai Uji", "Simpan" | hijau pekat, teks putih |
| `seken` | batal, navigasi sekunder | garis kontrol, teks tinta |
| `bahaya` | hapus, lepas, nonaktifkan | teks merah di atas permukaan |

```css
button, .tombol {
  min-height: 48px;
  padding: var(--s3) var(--s5);
  border-radius: var(--r2);
  font: inherit;
  font-weight: 600;
  border: 1px solid transparent;
  cursor: pointer;
  touch-action: manipulation;   /* hilangkan delay 300ms di tap lama */
}
.tombol-utama { background: var(--hijau); color: #fff; }
.tombol-utama:hover  { background: var(--hijau-pekat); }
.tombol-utama:active { transform: translateY(1px); }
.tombol-seken { background: var(--permukaan); color: var(--tinta); border-color: var(--garis-kontrol); }
.tombol-bahaya { background: var(--permukaan); color: var(--salah); border-color: var(--salah); }
```

`min-height: 48px` bukan aturan WCAG (itu 44px). Alasannya praktis: jarinya
ustadz sering lembap atau berselimut setelah wudu, dan target 44px sering
terlewat dalam praktik. Ini kalibrasi perangkat, bukan standar.

Tombol dengan efek samping tidak pernah `<a>`, dan tautan yang memindahkan
halaman tidak pernah `<button>`. Kotak bisa terlihat sama, tapi tag yang
salah berarti keyboard dan pembaca layar salah.

**Setiap tombol punya keadaan.** Tidak ada tombol mati tanpa alasan:

```css
button:disabled          { opacity: .5; cursor: not-allowed; }
button[aria-busy="true"] { cursor: progress; }
```

`aria-busy` dipakai saat sedang menyimpan supaya pembaca layar tahu tombolnya
masih hidup, bukan mati.

### 6.3 Input dan form

```css
input, select, textarea {
  width: 100%;
  min-height: 48px;
  padding: var(--s3) var(--s4);
  background: var(--permukaan);
  color: var(--tinta);
  border: 1px solid var(--garis-kontrol);
  border-radius: var(--r2);
  font: inherit;
}
```

`width: 100%` selalu. Input yang hanya selebar kontennya adalah tanda
formulir yang belum dirancang, dan langsung menyakitkan saat diisi.

Label selalu ada dan selalu di atas, tidak pernah jadi `placeholder`.
Placeholder lenyap begitu diisi, jadi field tanpa label berarti orang tidak
tahu lagi apa isinya. Placeholder hanya untuk contoh format:
`email@contoh.com`, `Contoh: A1B2C3`.

Field dengan lima opsi atau kurang **tidak** memakai native `select` di
shell A. Alasannya: roda pilihan bawaan menutupi separuh layar dan memaksa
sepuluh ketukan untuk memilih satu dari lima kelompok. Tapi kalau opsinya
lebih dari 12, roda itu justru menang karena mengetik lebih cepat daripada
menggulir. Batas dua belas bukan angka bulat, itu hasil hitung: satu daun
menggeser daftar 20 opsi butuh lima ketukan yang tidak bisa dipercepat.

### 6.4 Kartu dan baris daftar

Kartu datar, dipisah garis rambut, tanpa bayangan:

```css
.kartu {
  background: var(--permukaan);
  border: 1px solid var(--garis);
  border-radius: var(--r3);
  padding: var(--s4);
}
```

Baris daftar dibuat penuh dengan `min-height: 60px`: avatar di kiri, nama
dan meta di tengah, chevron di kanan. Baris daftar adalah kontrol, jadi
ikut punya state tekan:

```css
.baris-daftar:active { background: var(--hijau-muda); }
```

Chevron hanya di baris yang benar-benar bisa dibuka. Ikon panah di baris
yang tidak melakukan apa-apa adalah komponen bohong.

### 6.5 Status: benar, dibantu, salah

Tiga status ini inti produk, jadi harus terbaca dalam satu detik dan tetap
terbaca tanpa warna.

| Status | Ikon | Latar | Teks |
|---|---|---|---|
| `benar` | centang | hijau muda `#eef4f0` | `#1f6b45` |
| `dibantu` | setengah penuh | amber muda `#faf1de` | `#8a5a12` |
| `salah` | silang | merah muda `#faf0ee` | `#a33227` |

Ikon selalu ikut warna, tidak pernah warna saja (`antislop-human`: status
yang hanya mengandalkan warna hilang total di mode kontras paksa). Bentuk
ikonnya berbeda satu sama lain: `centang`, `setengah`, `silang`, supaya
membedakannya tidak perlu melihat warna sama sekali.

### 6.6 Tabel

Dua perilaku, dipilih sesuai lebar data, bukan sesuai breakpoint ponsel.

**Tabel leger di shell A (< 900px)**: tidak jadi kartu, tidak jadi
accordion. Alasannya: leger adalah tabel dengan 13 kolom, dan mengubahnya
jadi kartu menyembunyikan perbandingan antar Santri, yang justru tujuan
halaman ini. Solusinya scroll horizontal di dalam kotak, bukan di halaman.

```css
.gulir {
  overflow-x: auto;
  -webkit-overflow-scrolling: touch;
  border: 1px solid var(--garis);
  border-radius: var(--r3);
  overscroll-behavior-x: contain;   /* scroll halaman ikut berhenti */
}
.gulir > table { min-width: 720px; }
```

Kolom nama diberi `position: sticky; left: 0` dengan latar `--permukaan`,
supaya saat menggulir ke kanan nama Santri tetap terlihat. Tanpa ini kolom
angka kehilangan identitasnya dan leger jadi tidak berguna.

`min-width: 720px`: 13 kolom dengan nama 120px dan angka 40px butuh 680px
sebelum teks mulai saling tumpang tindih.

**Tabel admin di shell A**: tiga kolom atau lebih berubah jadi daftar kartu
satu per baris, dengan label dan nilai berpasangan. Alasannya: tabel tiga
kolom yang digulir horizontal di HP dibaca lebih lambat daripada daftar
kartu yang seluruh isinya langsung terlihat.

**Di shell B (>= 900px)**: tabel penuh, tanpa scroll horizontal, karena
ruang konten 1100px sudah cukup untuk leger.

### 6.7 Dialog

Hanya satu elevated surface, jadi satu bayangan.

```css
.overlay {
  position: fixed; inset: 0;
  display: flex; align-items: center; justify-content: center;
  padding: var(--s4);
  background: rgba(27, 36, 32, .45);
}
.dialog {
  width: 100%; max-width: 460px;
  max-height: min(90dvh, 720px);
  overflow-y: auto;
  background: var(--permukaan);
  border: 1px solid var(--garis);
  border-radius: var(--r3);
  box-shadow: var(--bayang-1);
}
```

Di bawah 480px dialog jadi sheet dari bawah dengan `--r4` di atas dan
`align-items: flex-end`. Alasannya: di 360px dialog yang terpusat memaksa
kepala berada jauh dari jangkauan ibu jari, sementara sheet bisa dijangkau
sambil melihat isi di belakangnya.

Dialog wajib `role="dialog"`, `aria-modal="true"`, label terhubung, dan
tertutup dengan `Escape`. `Teleport to="body"` supaya tidak ikut terpotong
`overflow` induk.

### 6.8 Toast

Toast untuk konfirmasi singkat. Untuk hal penting, toast tidak cukup: pesan
hilang sendiri, sedangkan "Akun berhasil dibuat" atau "Nilai tidak
tersimpan" harus berhenti sampai dibaca.

Toast sudah berada di kanan atas (`top: 16px; right: 16px`), jadi tidak
perlu dihitung ulang terhadap navigasi bawah. Yang harus dijaga: di HP toast
tidak boleh lebih dari 320px, dan tidak boleh menimpa navigasi bawah saat
ikut ter-scroll ke bawah layar.

```css
.toast-container {
  position: fixed; top: var(--s4); right: var(--s4);
  max-width: 320px;
}
```

Kiri atas bukan pilihan: toast muncul karena ada aksi baru, dan navigasi
selalu ada. Menaruh toast di kiri akan membuatnya terlihat seperti bagian
dari navigasi.

### 6.9 Cetak

`@media print` punya aturan sendiri, bukan sekadar menyembunyikan navigasi.
Latar jadi putih, teks jadi hitam, garis tetap hitam, dan navigasi serta
tombol hilang. Alasannya: leger yang dicetak adalah dokumen resmi yang
dibawa ke ruang asatidz.

```css
@media print {
  :root { --kertas: #fff; --permukaan: #fff; --tinta: #000; --tinta-2: #333; --garis: #999; }
  .nav-bawah, .sidebar, .tombol, .toast, .nocetak { display: none !important; }
  .isi { max-width: none; padding: 0; }
  table { font-size: 10pt; }
  thead { display: table-header-group; }  /* judul kolom ulang di tiap halaman */
  tr { break-inside: avoid; }
}
```

`thead { display: table-header-group }` yang membuat kolom nomor soal tetap
tertulis di setiap halaman kertas. Tanpa itu, halaman kedua leger kehilangan
keterangan kolomnya.

---

## 7. State: setiap tampilan data punya tiga wajah

Halaman yang menampilkan data punya tiga state. Ketiganya wajib ada, dan
masing-masing harus menyebut **penyebab** dan **jalur berikutnya**, bukan
sekadar "Tidak ada data".

| State | Isi | Contoh kalimat |
|---|---|---|
| Kosong | kenapa kosong, dan satu aksi yang mengisinya | "Belum ada nilai untuk 12 Mei 2026. Uji dimulai dari layar Mulai." |
| Memuat | apa yang sedang dimuat, dengan teks | "Memuat leger 12 Mei 2026..." |
| Galat | apa yang gagal, dan apa yang bisa dilakukan | "Gagal memuat leger. Periksa sinyal, lalu coba lagi." |

Tiga kalimat di atas bukan contoh karangan: itu bentuk kalimat yang dipakai
di seluruh aplikasi. Galat selalu diikuti jalan keluar. "Tidak ada data"
tanpa penjelasan adalah state yang tidak menyelesaikan apa pun
(`antislop` R-27).

Empat keadaan yang berbeda, empat tampilan berbeda:

| Keadaan | Yang ditampilkan |
|---|---|
| Pertama kali dipakai | Ajakan mulai, dengan tombol yang jelas |
| Difilter sampai kosong | "Tidak ada Santri bernama 'Ali' di kelas 2." + tombol Hapus Filter |
| Belum punya izin | "Menu ini hanya untuk superadmin." tanpa tombol yang mati |
| Gagal memuat | Pesan galat + tombol "Coba lagi" yang benar-benar memuat ulang |

Keempatnya tidak boleh memakai komponen yang sama. Placeholder seperti
"John Doe" atau "Data tidak tersedia" dilarang (`R-23`, `R-38`): kolom
kosong lebih jujur daripada data palsu.

---

## 8. Aksesibilitas

Ini bukan daftar tambahan di akhir. UI yang tidak bisa dipakai keyboard
atau tidak terbaca di bawah cahaya terang dianggap belum jadi UI.

### Fokus keyboard

Tidak ada `outline: none` tanpa pengganti. Di `main.css` lama ada
`input:focus { outline: none }`, dan itu persis yang dilarang.

```css
:focus-visible {
  outline: 2px solid var(--hijau);
  outline-offset: 2px;
  border-radius: var(--r2);
}
@media (prefers-contrast: more) {
  :focus-visible { outline-width: 3px; }
}
```

`--hijau` di `#fffdf8` terpilih 8.54:1, jauh di atas ambang 3:1 yang diminta
WCAG 1.4.11 untuk indikator fokus. Di mode gelap cincinnya jadi `#7d9b8a`
(5.30:1), tetap lolos.

`:focus-visible`, bukan `:focus`, supaya klik mouse tidak menyisakan cincin
di setiap tombol, tapi keyboard selalu terlihat jelas.

### Kontras

Semua angka ada di tabel bagian 2. Tidak ada pasangan warna yang boleh
dibuat tanpa dihitung ulang. Kalau muncul warna baru, jalankan:

```
python C:\Users\pondo\.claude\skills\antislop-human\contrast-check.py "#WARNA" "#LATAR"
```

### Gerak

Semua transisi tunduk pada `prefers-reduced-motion`:

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: .01ms !important;
    transition-duration: .01ms !important;
  }
}
```

Sebagian orang punya gangguan vestibular. Transisi yang bergeser cukup
jauh adalah masalah nyata bagi mereka. Ini kondisi yang harus benar, bukan
penyesuaian.

### Zoom

Tidak ada `overflow: hidden` pada wadah yang memuat teks. Semua ukuran font
dalam `rem` atau `clamp()`, tidak ada tinggi kontainer tetap yang memotong
isi. Pada 200% zoom di 360px (setara 720px efektif) layout harus tetap
terbaca, dan itu yang diuji.

### Layar sentuh

Semua target interaktif minimal 48x48px, jarak minimal 8px antar target.
Tiga tombol verdict pada layar tangga berbagi satu baris: di 360px
masing-masing 109px, jauh di atas minimum. Di bawah itu tombolnya jadi satu
kolom, bukan dipadatkan.

---

## 9. Gerbang pengiriman

Tidak ada PR UI yang lolos tanpa checklist ini. Yang gagal, diperbaiki dulu.

### Block 1: Wajib mutlak

Semua jawaban harus "tidak":

- [ ] Ada tanda hubung panjang di teks mana pun? (R-02)
- [ ] Ada overflow horizontal, teks keluar kotak, atau layout pecah di HP? (R-03)
- [ ] Ada angka statistik tanpa sumber nyata? (R-17)
- [ ] Ada testimoni rekaan? (R-18)
- [ ] Ada tombol, dropdown, atau form yang tidak melakukan apa-apa? (R-26)
- [ ] Ada tampilan data tanpa state kosong, memuat, atau galat? (R-27)
- [ ] Ada item navigasi yang menuju halaman yang tidak ada? (R-24)
- [ ] Ada teks dengan kontras di bawah 4.5:1, atau 3:1 untuk teks besar? (R-25)
- [ ] UI tidak bisa dinavigasi dengan keyboard, atau fokus tidak terlihat? (R-32)
- [ ] Ada `outline: none` tanpa pengganti? (R-32)
- [ ] Ada fitur yang dipaksakan lewat skrip luar, bukan ditulis di sumber? (R-33)

### Block 2: Anti-slop

- [ ] Palet berasal dari identitas proyek, bukan gradient bawaan? (R-01, R-29)
- [ ] Aksen dipakai pada momen kunci saja, bukan tersebar? (satu aksen)
- [ ] Copy bebas dari emoji dekoratif di judul dan tombol? (R-04)
- [ ] Layout bebas dari shape bawaan AI: bento grid, terminal palsu, tiga kolom harga? (R-05)
- [ ] Glass, glow, bayangan, dan radius dipakai di bawah dosisnya? (R-10 s/d R-13)
- [ ] Tidak ada `backdrop-filter` di lebih dari satu komponen? (R-10)
- [ ] Setiap target sentuh minimal 44x44px dengan jarak? (R-03)
- [ ] Navigasi berubah pola di layar kecil, bukan desktop yang diperkecil? (R-03)
- [ ] Bar tetap tidak menutupi konten dan menghormati safe area? (R-03)
- [ ] Semua transisi tunduk pada `prefers-reduced-motion`? (R-19)
- [ ] Angka, delta, dan baris tabel nyata atau placeholder yang jujur? (R-38)

### Block 3: Khusus aplikasi ini

- [ ] Lafadz Arab muat tanpa terpotong di 320px dan tidak menggulir horizontal
- [ ] Tiga tombol verdict punya state tekan yang terasa di HP (`:active`)
- [ ] Kolom nama di leger masih terlihat saat tabel digulir ke kanan
- [ ] Baris terakhir daftar dan tombol Simpan tidak tertutup navigasi bawah
- [ ] Sheet di 360px tidak menutupi keyboard saat input difokus
- [ ] Dialog dapat ditutup dengan `Escape` dan mengembalikan fokus
- [ ] Mode gelap: semua pasangan warna dihitung ulang, bukan diasumsikan
- [ ] Cetak (`@media print`): leger terbaca hitam di atas putih, navigasi hilang

---

## 10. Temuan di `main.css` lama, dan statusnya

Diverifikasi ulang terhadap kode, bukan ingatan. Yang sudah dikerjakan ditandai.

| Temuan | Masalah | Status |
|---|---|---|
| `.container { max-width: 640px }` untuk semua ukuran | Di monitor 27 inci aplikasi seperti HP yang diperbesar | **Selesai**: dua shell |
| `@media (min-width: 640px) { .bottom-nav { display: none } }` | Di tablet dan desktop navigasi hilang tanpa pengganti | **Selesai**: ambang 900px + sidebar |
| `.wadah { composes: container }` | `composes` hanya berlaku di CSS Modules, jadi `.wadah` tanpa gaya sama sekali | **Selesai**: `.wadah` dan `.container` disatukan |
| `input:focus { outline: none }` dengan `box-shadow` pucat | Fokus keyboard nyaris tak terlihat | **Selesai**: `:focus-visible` 2px |
| `input::placeholder { opacity: 0.7 }` | Menurunkan kontras placeholder ke bawah ambang | **Selesai**: opacity 1 |
| `.grid-4` selalu 4 kolom, tanpa media query | Empat kartu di 360px = 84px tiap kartu, label terpotong | **Selesai**: 2 kolom, 4 mulai dari 700px |
| `.gulir` hanya `overflow-x: auto` | Kolom nama hilang saat digulir, leger jadi tidak berguna | **Selesai**: kolom nama `position: sticky` |
| `.grid { minmax(140px, 1px) }` | `max` lebih kecil dari `min`, aturan tidak masuk akal | **Selesai**: `1fr` |
| `--primary-light: #e8f0ec` | Sisa warna gradient, tidak pernah jadi warna brand | **Selesai**: `#e8efe9` dari hijau brand |
| `--secondary`, `--secondary-light` | Tidak dipakai satu pun file | **Selesai**: dihapus |
| `color: #fff` di tombol, toast, lafad | Di mode gelap teks putih hanya 3.03:1 | **Selesai**: token `--teks-aksen` |
| `'Inter'` di `font` | Tidak ada `@font-face` dan tidak ada `<link>` memuatnya | **Selesai**: huruf sistem saja |
| Bayangan di `.kartu`, `.stat-card`, `.modal` | Semua melayang, tidak ada yang jadi foreground | **Belum**: kartu masih berbayang |
| Radius 8/12/16/20 dipakai bergantian | Radius jadi dekorasi, bukan alat hierarki | **Belum**: token radius belum dirapikan |
| `@media print` hanya `body { background: #fff }` | Tabel cetak tanpa garis, judul kolom hilang di halaman kedua | **Belum**: lihat bagian 6.9 |
| Emoji sebagai ikon di banyak halaman | Bentuk berbeda tiap platform | **Sebagian**: navigasi bersih, halaman belum |
| Tombol "Keluar" dan tema dobel di desktop | Sidebar punya, halaman juga punya | **Belum**: lihat catatan di bawah |
| Beberapa halaman tidak punya "Keluar" sama sekali | Di HP mustahil keluar tanpa ke halaman beranda | **Belum** |

Dua catatan soal yang sengaja belum dikerjakan:

1. Bayangan dan radius sengaja ditunda. Semuanya terlihat, dan mengubahnya
   menyentuh hampir setiap komponen, jadi selisihnya besar tanpa pengaruh yang
   bisa dilihat sekarang.
2. "Keluar" dobel tidak bisa diselesaikan dengan aturan CSS, karena tombol
   `.kecil` dipakai untuk banyak hal (Edit, Hapus, Cetak, Ibarat). Menyembunyikan
   semua `.kecil` di desktop akan mematikan tombol yang justru dibutuhkan.
   Menyelesaikannya berarti memindahkan "Keluar" ke shell sepenuhnya, dan itu
   pekerjaan tersendiri.

---

## 11. Aturan untuk kerangka

Bagian 5 sudah jadi. Bentuk kerangka yang dipakai di `app.vue` sekarang:

```vue
<script setup lang="ts">
import { perluSidebar, halamanSendiri } from '~/utils/nav'

const { init } = useTheme()
const { role } = useAuth()
const lebar = useLebar()
const route = useRoute()

const tampilSidebar = computed(() => perluSidebar(route.path, role.value, lebar.value))
const tampilNavBawah = computed(() => !halamanSendiri(route.path))

onMounted(() => { init() })
</script>

<template>
  <div class="app-shell">
    <Sidebar v-if="tampilSidebar" />
    <div class="app-main">
      <NuxtPage />
    </div>
  </div>
  <BottomNav v-if="tampilNavBawah" />
  <BilahAntrean />
  <ToastContainer />
</template>
```

Empat keputusan yang tidak boleh dibalik tanpa alasan:

1. **Rute yang menentukan, bukan `role`.** `/` dan `/daftar-santri` disebut
   eksplisit di `HALAMAN_SENDIRI`, jadi tidak pernah dapat sidebar maupun
   navigasi bawah, pada lebar berapa pun dan sudah masuk atau belum.
   Syarat "sudah masuk" saja tidak cukup menyakikannya; lihat butir 2.
2. **`role` tetap ikut menentukan sidebar.** Tanpa itu, `/daftar-santri` milik
   santri yang baru daftar akan berkedip sidebar kosong selama `role` terisi
   tapi middleware belum selesai.
3. **`BottomNav` tidak memakai `v-if="!lebar"`.** Ia selalu ada di DOM lalu
   disembunyikan CSS. Kalau pakai `v-if`, ia di-mount ulang tiap navigasi.
4. **`Sidebar` dan `BottomNav` membaca `app/utils/nav.ts` yang sama**, jadi
   tidak mungkin isinya berbeda. Emoji sebagai ikon dihapus, bukan diganti.

Kalau nanti ada halaman baru yang berdiri sendiri (misalnya layar "internet
putus" atau "antrean penuh"), cukup tambahkan path-nya ke `HALAMAN_SENDIRI`.

Aturan yang berlaku untuk semua halaman berikutnya: **halaman tidak pernah
membuat layout sendiri.** Halaman hanya isi. Kalau sebuah halaman butuh
dua kolom, itu berarti bagian 5 salah, bukan halaman yang perlu route
tambahan.



