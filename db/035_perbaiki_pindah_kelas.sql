-- 035: perbaikan pindah_kelas. Dua bug di percobaan pertama:
--   1. Nama kolom salah ketik. Tubuh plpgsql hanya diresolusi saat
--      DIJALANKAN, jadi fungsi berhasil dibuat lalu meledak saat dipanggil.
--      Persis kelas bug yang sudah tercatat di docs/00-project-rules.md:43.
--   2. `if v_lama = v_baru` membandingkan NAMA kelompok. Kalau v_lama NULL
--      (belum punya kelas), hasilnya NULL dan `if NULL` dianggap FALSE --
--      cabang "pindah" terambil karena alasan yang salah, bukan karena benar.
--
-- Yang benar: bandingkan ID (dijamin unik), dan pakai `is not distinct
-- from` supaya aman terhadap NULL di kedua sisi.

create or replace function public.pindah_kelas(
  p_santri_id   bigint,
  p_kelompok_id bigint
) returns void
  language plpgsql security definer set search_path = '' as
$$
declare
  v_santri text;
  v_lama   bigint;
  v_baru   bigint;
  v_jenis  text;
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa memindahkan santri antar kelas.';
  end if;

  select s.nama into v_santri from public.santri s where s.id = p_santri_id;
  if v_santri is null then
    raise exception 'Santri tidak ditemukan.';
  end if;

  select k.id, k.jenis into v_baru, v_jenis
    from public.kelompok k where k.id = p_kelompok_id;
  if v_baru is null then
    raise exception 'Kelompok tujuan tidak ditemukan.';
  end if;

  -- Yang ditutup hanya membership dengan jenis YANG SAMA: kalau seorang
  -- santri ada di satu sorogan dan satu terjemah, memindahkan sorogan tidak
  -- boleh ikut menutup terjemah.
  select ks.kelompok_id into v_lama
    from public.kelompok_santri ks
    join public.kelompok k on k.id = ks.kelompok_id
   where ks.santri_id = p_santri_id and ks.sampai is null and k.jenis = v_jenis;

  if v_lama is not distinct from v_baru then
    raise exception '% sudah ada di kelompok itu.', v_santri;
  end if;

  if v_lama is not null then
    update public.kelompok_santri
       set sampai = current_date
     where ks.santri_id = p_santri_id
       and kelompok_id = v_lama
       and sampai is null;
  end if;

  insert into public.kelompok_santri (kelompok_id, santri_id, dari)
  values (p_kelompok_id, p_santri_id, current_date);
end
$$;

-- Default privileges Supabase memberi EXECUTE ke `anon` SECARA EKSPLISIT,
-- jadi `revoke from public` saja tidak cukup (lihat 030).
revoke execute on function public.pindah_kelas(bigint, bigint) from public;
revoke execute on function public.pindah_kelas(bigint, bigint) from anon;
grant execute on function public.pindah_kelas(bigint, bigint) to authenticated;
