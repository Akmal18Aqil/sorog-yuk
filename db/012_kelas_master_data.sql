-- KELAS jadi master data, bukan lagi nilai teks yang dipatok CHECK constraint.
--
-- Yang dibeli: ambang kenaikan jadi DATA, bukan angka di dalam kode. Dan
-- menambah Kelas 3 nanti cukup satu INSERT — bukan migrasi untuk mengubah
-- CHECK di dua tabel sekaligus.
--
-- `kode` ('BK1'/'BK2') dipakai sebagai kunci relasi, bukan id angka, supaya
-- seluruh kode aplikasi yang sudah ada tetap berbicara 'BK1'/'BK2' tanpa
-- perubahan apa pun. Referential integrity menggantikan CHECK.
create table kelas (
  id             bigint generated always as identity primary key,
  kode           text not null unique,
  nama           text not null,
  urutan         int  not null unique,
  ambang_online  numeric not null default 70 check (ambang_online  between 0 and 100),
  ambang_offline numeric not null default 70 check (ambang_offline between 0 and 100)
);

insert into kelas (kode, nama, urutan) values
  ('BK1', 'Kelas 1 — Baca Kitab 1', 1),
  ('BK2', 'Kelas 2 — Baca Kitab 2', 2);

alter table santri drop constraint santri_tingkat_check;
alter table santri add  constraint santri_tingkat_fk
  foreign key (tingkat) references kelas(kode) on update cascade;

alter table soal drop constraint soal_tingkat_check;
alter table soal add  constraint soal_tingkat_fk
  foreign key (tingkat) references kelas(kode) on update cascade;

-- Kolom lama yang tak pernah terisi (0 dari 20 baris) dan sekarang namanya
-- justru menyesatkan: "kelas" kini berarti tabel di atas, sedangkan kolom ini
-- dimaksudkan sebagai rombel dan tidak pernah dipakai.
alter table santri drop column kelas;

alter table kelas enable row level security;
create policy baca on kelas for select to authenticated using (priv.is_ustadz());
