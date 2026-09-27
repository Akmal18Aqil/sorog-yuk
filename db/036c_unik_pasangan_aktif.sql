-- 036c: UNIQUE parsial per pasangan. Yang sudah ditutup boleh diulang --
-- hanya membership AKTIF yang dikunci. Ini yang menggantikan jaminan yang
-- dulunya datang dari PK (036b).

create unique index if not exists kelompok_santri_pasangan_aktif
  on public.kelompok_santri (kelompok_id, santri_id)
  where sampai is null;
