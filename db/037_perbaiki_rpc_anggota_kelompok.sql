-- 037: perbaiki tambah/hapus anggota kelompok (dari 018).
--
-- `tambah_anggota_kelompok` (018) tidak lagi cukup setelah 033/036.
--
-- Yang berubah: `ON CONFLICT DO NOTHING` dulu menangkap bentrok PRIMARY KEY
-- (kelompok_id, santri_id). Sekarang PK-nya `id`, jadi bentrok itu tidak
-- pernah terjadi lagi -- dan `ON CONFLICT DO NOTHING` tanpa target tidak
-- menangkap apa pun. Hasilnya: seorang Santri bisa masuk ke DUA kelompok
-- AKTIF sekaligus, tanpa error, diam-diam.
--
-- Bukti nyata, bukan teori: "pindah ke 2, tambah lagi ke 2" lolos tanpa
-- error. Itu persis keadaan yang harus mustahil.
--
-- Perbaikannya: cek dulu, dan beri pesan yang mengarah ke pindah_kelas
-- (036) yang menutup yang lama dan membuka yang baru dalam satu operasi.
--
-- `hapus_anggota_kelompok` tidak lagi menghapus baris -- ia menutup
-- membership. Kalau dihapus, kita kembali ke kondisi sebelum 033: riwayat
-- perpindahan lenyap begitu admin memindahkan anak.

create or replace function public.tambah_anggota_kelompok(
  p_kelompok_id bigint,
  p_santri_id   bigint
) returns void
  language plpgsql security definer set search_path = '' as
$$
declare v_santri text; v_lama text;
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa mengelola anggota kelompok.';
  end if;

  select s.nama into v_santri from public.santri s where s.id = p_santri_id;
  if v_santri is null then
    raise exception 'Santri tidak ditemukan.';
  end if;

  if not exists (select 1 from public.kelompok where id = p_kelompok_id) then
    raise exception 'Kelompok tujuan tidak ditemukan.';
  end if;

  -- Sudah di kelompok yang sama (aktif): diamkan saja, supaya tombol yang
  -- ditekan dua kali tidak terasa rusak.
  if exists (select 1 from public.kelompok_santri ks
              where ks.santri_id = p_santri_id
                and ks.kelompok_id = p_kelompok_id
                and ks.sampai is null) then
    return;
  end if;

  select k.nama into v_lama
    from public.kelompok_santri ks
    join public.kelompok k on k.id = ks.kelompok_id
   where ks.santri_id = p_santri_id and ks.sampai is null;

  if v_lama is not null then
    raise exception
      '% masih ada di %. Gunakan pindah kelas agar riwayatnya tercatat.', v_santri, v_lama;
  end if;

  insert into public.kelompok_santri (kelompok_id, santri_id, dari)
  values (p_kelompok_id, p_santri_id, current_date);
end
$$;

create or replace function public.hapus_anggota_kelompok(
  p_kelompok_id bigint,
  p_santri_id   bigint
) returns void
  language plpgsql security definer set search_path = '' as
$$
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa mengelola anggota kelompok.';
  end if;
  update public.kelompok_santri set sampai = current_date
   where santri_id = p_santri_id and kelompok_id = p_kelompok_id and sampai is null;
end
$$;

revoke execute on function public.tambah_anggota_kelompok(bigint, bigint) from public;
revoke execute on function public.tambah_anggota_kelompok(bigint, bigint) from anon;
revoke execute on function public.hapus_anggota_kelompok(bigint, bigint) from public;
revoke execute on function public.hapus_anggota_kelompok(bigint, bigint) from anon;
grant execute on function
  public.tambah_anggota_kelompok(bigint, bigint),
  public.hapus_anggota_kelompok(bigint, bigint)
to authenticated;
