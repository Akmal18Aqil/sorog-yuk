-- Empat kelompok isi lima santri, mengikuti pembagian di leger asli.
-- Namanya sengaja netral (bukan "Kelompok Ust. Ghofar"): pengujinya yang
-- berotasi, kelompoknya yang tetap.
insert into kelompok (nama, urutan) values
  ('Kelompok 1', 1), ('Kelompok 2', 2), ('Kelompok 3', 3), ('Kelompok 4', 4);

insert into kelompok_santri (kelompok_id, santri_id)
select k.id, s.id
from (values
  ('Kelompok 1', 'Satria'), ('Kelompok 1', 'Reyhan'), ('Kelompok 1', 'Nashir'),
  ('Kelompok 1', 'Faaiq'), ('Kelompok 1', 'Ach. Muzaki'),
  ('Kelompok 2', 'Abu Reihan'), ('Kelompok 2', 'Chusnillah'), ('Kelompok 2', 'Fahmi I'),
  ('Kelompok 2', 'Fahmi A.'), ('Kelompok 2', 'Raihan Muzakki'),
  ('Kelompok 3', 'Jadid'), ('Kelompok 3', 'Adam'), ('Kelompok 3', 'Rafi'),
  ('Kelompok 3', 'Afandi'), ('Kelompok 3', 'Zada'),
  ('Kelompok 4', 'Agil'), ('Kelompok 4', 'Hilmi'), ('Kelompok 4', 'Athoillah'),
  ('Kelompok 4', 'Ubaid'), ('Kelompok 4', 'Rubahul Faiz')
) as x(kelompok, santri)
join kelompok k on k.nama = x.kelompok
join santri   s on s.nama = x.santri;
