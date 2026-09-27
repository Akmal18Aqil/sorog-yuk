# 13 — Komunikasi Antar Agen

## Bentuk serah-terima

Satu blok teks, bukan prosa. Agen berikutnya harus bisa bekerja **tanpa membaca
percakapan sebelumnya**.

```
DARI      : <agen>
KE        : <agen>
LINGKUP   : <satu kalimat>
BERKAS    : <path yang disentuh, atau "belum ada">
ATURAN    : <R-x yang mengikat>
STATUS    : selesai / terhalang / perlu putusan
BUKTI     : <perintah yang dijalankan + hasilnya, angka apa adanya>
BELUM     : <yang tidak dikerjakan + alasan>
TERUSKAN  : <apa yang harus dilakukan penerima>
```

Aturan mengikat: **`BUKTI` berisi keluaran nyata, bukan ringkasan.**
"test hijau" tidak cukup; "27 tes lolos, `nilai 75.0 vs datar 67.9`" cukup.

## Contoh serah-terima nyata

```
DARI      : Backend
KE        : QA
LINGKUP   : Gerbang kenaikan kelas (dua tes + keputusan asatidz)
BERKAS    : db/012, db/013, db/014, shared/types/database.ts, app/utils/repo.ts
ATURAN    : R1 (nilai tidak disimpan) · R5 (RPC diuji sungguhan) · R11 (asatidz memutuskan)
STATUS    : selesai
BUKTI     : db/014 → NAIK_OK_ROLLBACK | lintas-kelas ditolak |
            daring=100 luring=90(tes ulang) siap=t | tingkat->BK2 |
            tanpa-alasan: "Menaikkan di luar ambang harus disertai catatan alasan."
            npm run typecheck → EXIT=0
BELUM     : UI /kenaikan belum diukur di 375px
TERUSKAN  : Ukur tata letak halaman /kenaikan; jalankan gerbang penuh
```

## Jalur yang sah

```
Orchestrator ─┬─▶ Architect ──▶ Planner ──▶ Backend ─┬─▶ QA ──▶ Reporter
              │                          └─ Frontend ┘   │
              ├─▶ Debug ──▶ (pelaksana)                  │
              ├─▶ Security ◀────────────────────────────┘
              └─▶ DevOps ──▶ Reporter
```

- Pelaksana **tidak** menyerahkan langsung ke Reporter. Selalu lewat QA.
- Security bisa memveto kapan saja, termasuk setelah QA lolos.
- Debug tidak pernah dilewati untuk laporan gejala. Menambal tanpa Debug
  melanggar `09-debug-agent.md`.

## Eskalasi ke manusia

Hanya lewat Orchestrator, dan hanya kalau dua tafsir menghasilkan pekerjaan yang
**berbeda secara material**. Bentuknya:

```
PERTANYAAN : <satu pertanyaan, konkret>
PILIHAN    : <2–4 opsi, masing-masing dengan konsekuensi kerjanya>
BILA TIDAK DIJAWAB : <asumsi yang akan dipakai supaya pekerjaan tetap jalan>
```

Baris terakhir wajib. Pertanyaan tanpa rencana cadangan menghentikan pekerjaan
tanpa alasan.

## Konflik antar agen

Urutan kewenangan kalau ada tabrakan:

1. `00-project-rules.md` — menang atas semuanya
2. Security — soal data santri dan RLS
3. Architect — soal bentuk sistem
4. QA — soal boleh rilis atau tidak
5. sisanya

Kalau `00-project-rules.md` sendiri yang dianggap salah: itu keputusan manusia,
bukan agen. Eskalasikan.

## Yang tidak boleh terjadi

- Serah-terima yang mengandalkan ingatan percakapan.
- `BUKTI` yang berisi kata sifat.
- Dua agen mengerjakan berkas yang sama tanpa Orchestrator tahu.
- Melewati QA karena "perubahannya kecil". Dua bug nyata di proyek ini berasal
  dari perubahan yang terlihat kecil: satu ref yang tidak terbuka, dan satu
  whitespace yang hilang.
