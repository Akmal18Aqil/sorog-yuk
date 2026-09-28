-- 056: perketat simpan_penilaian dengan cek scope tugas (mundur-kompatibel).
--
-- Dibangun ulang penuh dari definisi LIVE (bukan db/005 yang sudah basi:
-- live sudah memakai p_kelompok_id + conflict 4 kolom). Tambahan hanya blok
-- cek tugas; sisanya identik supaya antrean offline tidak berubah perilaku.

create or replace function public.simpan_penilaian(
  p_tanggal   date,
  p_mode      text,
  p_santri_id bigint,
  p_urutan    integer,
  p_jawaban   jsonb,
  p_soal_id   bigint default null,
  p_ibarat_id bigint default null,
  p_lafad     text   default null,
  p_kelompok_id bigint default null
) returns bigint
  language plpgsql set search_path = '' as
$$
declare v_ust bigint; v_sesi bigint; v_soal bigint; v_pen bigint;
begin
  v_ust := priv.my_ustadz_id();
  if v_ust is null then
    raise exception 'Akun belum terhubung ke ustadz mana pun.';
  end if;

  -- Kosong = semua terbuka (hari ini). Berisi = hanya tugasnya. Superadmin lolos.
  if not priv.is_superadmin()
     and p_kelompok_id is not null
     and exists (select 1 from public.tugas_kelompok)
     and not exists (select 1 from public.tugas_kelompok t
                      where t.kelompok_id = p_kelompok_id and t.ustadz_id = v_ust) then
    raise exception 'Kelompok ini bukan tugas Anda.';
  end if;

  insert into public.sesi (tanggal, ustadz_id, mode, kelompok_id)
       values (p_tanggal, v_ust, p_mode, p_kelompok_id)
  on conflict (ustadz_id, tanggal, mode, kelompok_id) do update set mode = excluded.mode
    returning id into v_sesi;

  v_soal := p_soal_id;
  if v_soal is null then
    if p_ibarat_id is null or btrim(coalesce(p_lafad, '')) = '' then
      raise exception 'Soal tidak lengkap: butuh soal_id, atau ibarat_id + lafad.';
    end if;
    insert into public.soal (ibarat_id, teks, tipe, tingkat)
         values (p_ibarat_id, btrim(p_lafad), 'lafad', 'BK1')
    on conflict (ibarat_id, teks, tipe) do nothing;
    select id into v_soal from public.soal
     where ibarat_id = p_ibarat_id and teks = btrim(p_lafad) and tipe = 'lafad';
  end if;

  insert into public.penilaian (sesi_id, santri_id, soal_id, urutan)
       values (v_sesi, p_santri_id, v_soal, p_urutan)
  on conflict (sesi_id, santri_id, urutan) do update set soal_id = excluded.soal_id
    returning id into v_pen;

  delete from public.jawaban where penilaian_id = v_pen;
  insert into public.jawaban (penilaian_id, langkah_id, verdict, detik)
  select v_pen, (j->>'langkah_id')::bigint, j->>'verdict', (j->>'detik')::numeric
    from jsonb_array_elements(p_jawaban) j;

  return v_pen;
end
$$;

revoke all on function
  public.simpan_penilaian(date, text, bigint, int, jsonb, bigint, bigint, text, bigint)
  from public, anon;
grant execute on function
  public.simpan_penilaian(date, text, bigint, int, jsonb, bigint, bigint, text, bigint)
  to authenticated;
