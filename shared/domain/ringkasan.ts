/**
 * Peringkasan untuk layar diagnostik. Murni dan bisa diuji.
 *
 * View Postgres memberi angka PER SANTRI. Untuk melihat gambaran kelas,
 * baris-baris itu harus digabung — dan penggabungannya wajib DITIMBANG
 * dengan jumlah pengamatan. Merata-ratakan persentase begitu saja membuat
 * santri yang cuma dinilai 1 kali berbobot sama dengan yang dinilai 40 kali,
 * lalu "anak-tangga terlemah se-kelas" menunjuk ke tempat yang salah dan
 * asatidz mengajar ulang materi yang keliru.
 */

export interface SumberKelemahan {
  tipe: string | null
  urutan: number | null
  pertanyaan: string | null
  n: number | null
  nilai: number | null
}

export interface Kelemahan {
  kunci: string
  tipe: string
  urutan: number
  pertanyaan: string
  n: number
  nilai: number
}

export function gabungKelemahan(baris: readonly SumberKelemahan[]): Kelemahan[] {
  const peta = new Map<string, Kelemahan & { bobot: number }>()
  for (const b of baris) {
    if (!b.pertanyaan || b.n == null || b.nilai == null) continue
    const kunci = `${b.tipe}|${b.urutan}`
    const kini = peta.get(kunci) ?? {
      kunci, tipe: b.tipe ?? '', urutan: b.urutan ?? 0,
      pertanyaan: b.pertanyaan, n: 0, nilai: 0, bobot: 0,
    }
    kini.n += b.n
    kini.bobot += b.nilai * b.n      // ditimbang, bukan rata-rata dari rata-rata
    peta.set(kunci, kini)
  }
  return [...peta.values()]
    .map(({ bobot, ...k }) => ({ ...k, nilai: Math.round((bobot / k.n) * 10) / 10 }))
    .sort((a, b) => a.nilai - b.nilai)
}

export interface SumberNilaiSantri {
  santri_id: number | null
  jml_soal: number | null
  nilai: number | null
}

export interface NilaiSantri { santri_id: number, jml_soal: number, nilai: number }

/** Gabung beberapa sesi untuk satu santri — juga ditimbang jumlah soal. */
export function gabungNilaiSantri(baris: readonly SumberNilaiSantri[]): NilaiSantri[] {
  const peta = new Map<number, { jml_soal: number, bobot: number }>()
  for (const b of baris) {
    if (b.santri_id == null || b.jml_soal == null || b.nilai == null) continue
    const kini = peta.get(b.santri_id) ?? { jml_soal: 0, bobot: 0 }
    kini.jml_soal += b.jml_soal
    kini.bobot += b.nilai * b.jml_soal
    peta.set(b.santri_id, kini)
  }
  return [...peta.entries()]
    .map(([santri_id, v]) => ({
      santri_id, jml_soal: v.jml_soal, nilai: Math.round((v.bobot / v.jml_soal) * 10) / 10,
    }))
    .sort((a, b) => b.nilai - a.nilai)
}
