-- Satu sesi per (ustadz, tanggal, mode). Mencegah sesi kembar kalau
-- antrean offline dikirim berbarengan.
alter table sesi add constraint sesi_unik unique (ustadz_id, tanggal, mode);

-- Satu panggilan = satu soal selesai dinilai, atomik dan AMAN DIULANG.
-- Ini yang membuat antrean offline sederhana: klien cukup menyimpan payload
-- dan mengirim ulang sampai berhasil, tanpa takut ganda.
-- SECURITY INVOKER: RLS tetap jadi satu-satunya penjaga.
create function public.simpan_penilaian(
  p_tanggal   date,
  p_mode      text,
  p_santri_id bigint,
  p_urutan    int,
  p_jawaban   jsonb,                 -- [{langkah_id, verdict, detik}]
  p_soal_id   bigint default null,   -- BK2: dari bank
  p_ibarat_id bigint default null,   -- BK1: hasil ketuk kata
  p_lafad     text   default null
) returns bigint
language plpgsql security invoker set search_path = '' as
$$
declare v_ust bigint; v_sesi bigint; v_soal bigint; v_pen bigint;
begin
  v_ust := priv.my_ustadz_id();
  if v_ust is null then
    raise exception 'Akun belum terhubung ke ustadz mana pun.';
  end if;

  insert into public.sesi (tanggal, ustadz_id, mode)
       values (p_tanggal, v_ust, p_mode)
  on conflict (ustadz_id, tanggal, mode) do update set mode = excluded.mode
    returning id into v_sesi;

  v_soal := p_soal_id;
  if v_soal is null then
    -- BK1: lafad hasil ketukan. Kata yang sama dari penguji berbeda menyatu
    -- ke satu baris soal, supaya bisa dibandingkan antar santri.
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

  -- Ganti total, bukan tambah: pengiriman ulang menghasilkan keadaan yang sama.
  delete from public.jawaban where penilaian_id = v_pen;
  insert into public.jawaban (penilaian_id, langkah_id, verdict, detik)
  select v_pen, (j->>'langkah_id')::bigint, j->>'verdict', (j->>'detik')::numeric
    from jsonb_array_elements(p_jawaban) j;

  return v_pen;
end
$$;

revoke all on function public.simpan_penilaian(date, text, bigint, int, jsonb, bigint, bigint, text)
  from public, anon;
grant execute on function public.simpan_penilaian(date, text, bigint, int, jsonb, bigint, bigint, text)
  to authenticated;
