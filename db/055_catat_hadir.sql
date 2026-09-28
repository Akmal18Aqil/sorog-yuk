-- 055: catat_hadir — absen + kendala, aman diulang (upsert tanggal+santri).
-- Pola sama seperti simpan_penilaian: antrean offline kirim ulang tanpa ganda.

create or replace function public.catat_hadir(
  p_tanggal     date,
  p_santri_id   bigint,
  p_status      text,
  p_kelompok_id bigint default null,
  p_kendala     text default null
) returns bigint
  language plpgsql security invoker set search_path = '' as
$$
declare v_ust bigint; v_id bigint;
begin
  v_ust := priv.my_ustadz_id();
  if v_ust is null then
    if not priv.is_superadmin() then
      raise exception 'Akun belum terhubung ke ustadz mana pun.';
    end if;
    select id into v_ust from public.ustadz
     where auth_id = (select auth.uid()) limit 1;
  end if;

  if p_status not in ('hadir','izin','sakit','alpa') then
    raise exception 'Status "%" tidak dikenal.', p_status;
  end if;

  -- Scope tugas: kosong = terbuka; berisi = hanya kelompok tugasnya.
  if not priv.is_superadmin()
     and p_kelompok_id is not null
     and exists (select 1 from public.tugas_kelompok)
     and not exists (select 1 from public.tugas_kelompok t
                      where t.kelompok_id = p_kelompok_id and t.ustadz_id = v_ust) then
    raise exception 'Kelompok ini bukan tugas Anda.';
  end if;

  insert into public.kehadiran (tanggal, santri_id, kelompok_id, ustadz_id, status, kendala)
  values (p_tanggal, p_santri_id, p_kelompok_id, v_ust, p_status,
          nullif(btrim(coalesce(p_kendala, '')), ''))
  on conflict (tanggal, santri_id) do update set
    kelompok_id = excluded.kelompok_id,
    ustadz_id   = excluded.ustadz_id,
    status      = excluded.status,
    kendala     = excluded.kendala
  returning id into v_id;
  return v_id;
end
$$;

revoke all on function public.catat_hadir(date, bigint, text, bigint, text) from public;
revoke all on function public.catat_hadir(date, bigint, text, bigint, text) from anon;
grant execute on function public.catat_hadir(date, bigint, text, bigint, text) to authenticated;
