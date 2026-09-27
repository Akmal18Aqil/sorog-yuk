-- 036a: tambah surrogate key. PK belum disentuh, supaya kalau langkah ini
-- gagal, tidak ada setengah perubahan yang tertinggal.

alter table public.kelompok_santri add column if not exists id bigint;
create sequence if not exists public.kelompok_santri_id_seq;

update public.kelompok_santri ks set id = nextval('public.kelompok_santri_id_seq')
 where id is null;

alter table public.kelompok_santri alter column id set default nextval('public.kelompok_santri_id_seq');
alter table public.kelompok_santri alter column id set not null;

create unique index if not exists kelompok_santri_id_uniq on public.kelompok_santri (id);
