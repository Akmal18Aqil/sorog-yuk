"""Bikin db/002_seed.sql langsung dari dokumen leger aslinya.

Alasan skrip ini ada: teks Arab bank soal TIDAK boleh diketik ulang tangan.
Satu harakat meleset = soal yang beda. Jadi sumber kebenarannya tetap file
.docx dari asatidz, dan seed selalu bisa dibangkitkan ulang darinya.

Stdlib saja. Jalankan:  python tools/buat_seed.py "<path Tes Lisan BK 2.docx>"
"""
import re, sys, zipfile
from pathlib import Path

# 60 soal terbagi rata 4 tipe. Ini fakta bank yang SEKARANG, bukan aturan —
# karena itu `tipe` ikut ditulis ke setiap baris soal, bukan dihitung ulang
# di aplikasi. Begitu asatidz menambah soal, cukup ubah peta ini.
RENTANG_TIPE = [(1, 15, "ismiyah"), (16, 30, "filiyah"),
                (31, 45, "nawasikh"), (46, 60, "tabi")]

TANGGA = {
    "lafad": [  # BK 1 — Leger Tes Lisan Baca Kitab 1
        ("Kalimat apa?", None, False),
        ("Tandanya apa?", None, False),
        ("I'robnya apa?", None, False),
        ("Tanda i'robnya apa?", None, False),
        ("Kenapa pakai tanda itu?", None, False),
        ("Ma'rifat atau nakiroh?", "isim", False),
        ("Kalau ma'rifat, termasuk yang mana?", "marifat", False),
        ("Penerapan lafad (ubah ke mufrod / tatsniyah / jamak)!", None, False),
        ("Isim mabni: isim dhomir, maushul, atau isyaroh?", "mabni", False),
    ],
    "ismiyah": [  # BK 2 — soal 1..15
        ("Jumlah ismiyah atau fi'liyah?", None, False),
        ("Jumlah ismiyah itu apa?", None, True),
        ("Mubtada'nya mana?", None, False),
        ("Apa pengertian mubtada'?", None, True),
        ("Termasuk mubtada' apa?", None, False),
        ("Khobarnya mana?", None, False),
        ("Khobar itu apa?", None, True),
        ("Termasuk khobar apa?", None, False),
        ("Tambahlah amil nawasikh! (كان / إنّ / ظنّ)", None, False),
    ],
    "filiyah": [  # BK 2 — soal 16..30
        ("Jumlah ismiyah atau fi'liyah?", None, False),
        ("Jumlah fi'liyah itu apa?", None, True),
        ("Fa'il / naib fa'ilnya mana?", None, False),
        ("Apa itu fa'il / naib fa'il?", None, False),
        ("Fa'ilnya dhahir atau dhomir?", None, False),
        ("Fi'il mabni ma'lum / majhulnya mana?", None, False),
        ("Kenapa mabni ma'lum / majhul?", None, False),
        ("Ubahlah ke ma'lum / majhul!", None, False),
    ],
    "nawasikh": [  # BK 2 — soal 31..45
        ("Ada amil nawasikh atau tidak?", None, False),
        ("Mana amil nawasikhnya?", None, False),
        ("Amalnya apa?", None, False),
        ("Mana isimnya?", None, False),
        ("Mana khobarnya?", None, False),
        ("Gantilah dengan amil nawasikh lain!", None, False),
        ("Buang amil nawasikhnya!", None, False),
    ],
    "tabi": [  # BK 2 — soal 46..60
        ("Ada tabi' atau tidak?", None, False),
        ("Yang mana tabi'nya?", None, False),
        ("Termasuk tabi' yang apa?", None, False),
        ("Apa pengertiannya?", None, False),
        ("Termasuk macam yang mana?", "selain_athaf", False),
        ("I'robnya apa?", None, False),
        ("Kenapa?", None, False),
        ("Matbu'nya mana?", None, False),
    ],
}

# Dari leger BK 1: empat kelompok isi lima santri.
#
# Nama kelompoknya netral, dan PENUGASAN ustadz->kelompok tidak diseed sama
# sekali. Pengujinya yang berotasi, kelompoknya yang tetap; penugasan tersimpan
# per sesi di `sesi.kelompok_id`, bukan melekat pada kelompok.
KELOMPOK = {
    "Kelompok 1": ["Satria", "Reyhan", "Nashir", "Faaiq", "Ach. Muzaki"],
    "Kelompok 2": ["Abu Reihan", "Chusnillah", "Fahmi I", "Fahmi A.", "Raihan Muzakki"],
    "Kelompok 3": ["Jadid", "Adam", "Rafi", "Afandi", "Zada"],
    "Kelompok 4": ["Agil", "Hilmi", "Athoillah", "Ubaid", "Rubahul Faiz"],
}
SANTRI = [s for anggota in KELOMPOK.values() for s in anggota]
USTADZ = ["Ust. Ghofar", "Ust. Farizqi", "Ust. Rafli", "Ust. Akmal"]


def baca_bank(path):
    """Ambil 60 soal dari tabel .docx. Dokumen memuat banknya dua kali;
    keduanya dibandingkan, dan beda sedikit pun langsung dianggap error."""
    xml = zipfile.ZipFile(path).read("word/document.xml").decode("utf8")
    xml = re.sub(r"</w:tc>", "|", re.sub(r"</w:tr>", "\n@@\n", xml))
    teks = re.sub(r"<[^>]+>", "", xml)

    bank = {}
    nomor = None
    for baris in teks.split("@@"):
        sel = [re.sub(r"[​-‏‪-‮]", "", s).strip()
               for s in baris.split("|")]
        sel = [s for s in sel if s]
        if not sel:
            continue
        if all(s.isdigit() for s in sel):
            nomor = [int(s) for s in sel]
            continue
        if nomor and len(sel) >= len(nomor):
            for n, t in zip(nomor, sel[-len(nomor):]):
                if n in bank and bank[n] != t:
                    raise SystemExit(f"Soal {n} tidak konsisten di dokumen:\n"
                                     f"  {bank[n]!r}\n  {t!r}")
                bank[n] = t
            nomor = None

    kurang = [n for n in range(1, 61) if n not in bank]
    if kurang:
        raise SystemExit(f"Soal hilang: {kurang}")
    return bank


def tipe_soal(n):
    return next(t for a, b, t in RENTANG_TIPE if a <= n <= b)


q = lambda s: "'" + s.replace("'", "''") + "'"


def main():
    docx = Path(sys.argv[1] if len(sys.argv) > 1
                else Path.home() / "Downloads" / "Tes Lisan BK 2.docx")
    bank = baca_bank(docx)

    out = ["-- DIBANGKITKAN oleh tools/buat_seed.py — jangan diedit tangan.",
           f"-- Sumber teks Arab: {docx.name}", "",
           "insert into kitab (nama) values ('Tarkib Umdah');", ""]

    out.append("-- 60 ibarat = 60 potongan tarkib dari bank soal asatidz.")
    out.append("-- Dipakai dua kali: sebagai soal BK 2, dan sebagai bahan")
    out.append("-- ketuk-kata untuk BK 1. Satu korpus, dua tingkat.")
    out.append("insert into ibarat (kitab_id, urutan, teks) values")
    out.append(",\n".join(
        f"  ((select id from kitab where nama='Tarkib Umdah'), {n}, {q(bank[n])})"
        for n in range(1, 61)) + ";")
    out.append("")

    out.append("insert into soal (ibarat_id, teks, tipe, tingkat, nomor_bank)")
    out.append("select i.id, i.teks, x.tipe, 'BK2', i.urutan")
    out.append("from ibarat i join (values")
    out.append(",\n".join(f"  ({n}, {q(tipe_soal(n))})" for n in range(1, 61)))
    out.append(") as x(n, tipe) on x.n = i.urutan;")
    out.append("")

    out.append("insert into langkah (tipe, urutan, pertanyaan, bersyarat, sekali_per_sesi) values")
    baris = [f"  ({q(tipe)}, {i}, {q(p)}, {q(c) if c else 'null'}, {str(s).lower()})"
             for tipe, langkah in TANGGA.items()
             for i, (p, c, s) in enumerate(langkah, 1)]
    out.append(",\n".join(baris) + ";")
    out.append("")

    out.append("insert into santri (nama) values")
    out.append(",\n".join(f"  ({q(n)})" for n in SANTRI) + ";")
    out.append("")

    out.append("insert into ustadz (nama) values")
    out.append(",\n".join(f"  ({q(n)})" for n in USTADZ) + ";")
    out.append("")

    out.append("insert into kelompok (nama, urutan) values")
    out.append(",\n".join(f"  ({q(k)}, {i})" for i, k in enumerate(KELOMPOK, 1)) + ";")
    out.append("")
    out.append("insert into kelompok_santri (kelompok_id, santri_id)")
    out.append("select k.id, s.id from (values")
    out.append(",\n".join(f"  ({q(kel)}, {q(nama)})"
                          for kel, anggota in KELOMPOK.items() for nama in anggota))
    out.append(") as x(kelompok, santri)")
    out.append("join kelompok k on k.nama = x.kelompok")
    out.append("join santri   s on s.nama = x.santri;")
    out.append("")

    # KODE KLAIM SENGAJA TIDAK DIBANGKITKAN DI SINI.
    #
    # Skrip ini idempoten dan sering dijalankan ulang (mis. setelah asatidz
    # menambah soal). Kalau kodenya ikut diacak tiap kali, file seed diam-diam
    # jadi berbeda dari kode yang sudah beredar di database dan sudah
    # diberikan ke asatidz — dan tidak ada yang menyadarinya sampai ada yang
    # gagal login. Rahasia tidak boleh lahir dari perintah yang diulang-ulang.
    # Lihat db/011_kode_ustadz.sql untuk membuat atau memutar kode.
    Path("db/002_seed.sql").write_text("\n".join(out) + "\n", encoding="utf8")
    print("db/002_seed.sql ditulis.")
    print(f"  ibarat 60 | soal 60 | langkah {sum(len(v) for v in TANGGA.values())}"
          f" | santri {len(SANTRI)} | ustadz {len(USTADZ)}"
          f" | kelompok {len(KELOMPOK)}")
    assert len(set(SANTRI)) == len(SANTRI), "ada nama santri kembar antar kelompok"
    print("Kode klaim TIDAK disentuh — buat/putar lewat db/011_kode_ustadz.sql.")


if __name__ == "__main__":
    main()
