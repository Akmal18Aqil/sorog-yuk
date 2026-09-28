-- 054: tugas_kelompok — siapa pegang kelompok apa.
--
-- Kosong = semua terbuka (kompatibel mundur dengan hari ini).
-- Berisi = musrif hanya kelompoknya. Enforce di RPC (UI bisa dilewati).
-- Superadmin selalu lolos.

create table if not exists public.tugas_kelompok (
  kelompok_id bigint not null references public.kelompok(id) on delete cascade,
  ustadz_id   bigint not null references public.ustadz(id) on delete cascade,
  primary key (kelompok_id, ustadz_id)
);

alter table public.tugas_kelompok enable row level security;

-- Dibaca semua yang login (untuk filter UI); ditulis superadmin via RPC.
drop policy if exists baca_login on public.tugas_kelompok;
create policy baca_login on public.tugas_kelompok for select to authenticated
  using (priv.is_ustadz() or priv.is_superadmin());
drop policy if exists tulis_admin on public.tugas_kelompok;
create policy tulis_admin on public.tugas_kelompok for all to authenticated
  using (priv.is_superadmin())
  with check (priv.is_superadmin());

-- Ganti total daftar tugas 1 kelompok dalam satu operasi.
create or replace function public.atur_tugas(
  p_kelompok_id bigint,
  p_ustadz_ids  bigint[]
) returns void
  language plpgsql security definer set search_path = '' as
$$
begin
  if not priv.is_superadmin() then
    raise exception 'Hanya superadmin yang bisa mengatur tugas.';
  end if;
  delete from public.tugas_kelompok where kelompok_id = p_kelompok_id;
  insert into public.tugas_kelompok (kelompok_id, ustadz_id)
  select p_kelompok_id, unnest(coalesce(p_ustadz_ids, '{}'));
end
$$;

revoke all on function public.atur_tugas(bigint, bigint[]) from public;
revoke all on function public.atur_tugas(bigint, bigint[]) from anon;
grant execute on function public.atur_tugas(bigint, bigint[]) to authenticated;
