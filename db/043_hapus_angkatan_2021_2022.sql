-- Buang angkatan 2021-2022 (semester 8) dari daftar absensi.
--
-- Import pertama (039) mengambil semua angkatan karena itu yang diminta
-- waktu itu. Sekarang cakupannya dikoreksi: hanya Ang 2023 ke yang
-- terbaru, yaitu semester I, III, V, VII. Ang 2021 dan Ang 2022 tidak
-- termasuk.
--
-- Dihapus lewat `hapus_santri` (026), bukan DELETE langsung: RPC itu
-- menolak baris berriwayat dengan pesan yang bisa dibaca. Kalau ternyata ada
-- riwayat yang terlewat, migrasi ini BERGAGAL dan tidak menghapus apa pun
-- -- lebih baik gagal keras daripada menghapus nilai tanpa jejak.
--
-- Dicek sebelum migration ini: 41 orang, nol akun auth, nol penilaian, nol
-- kenaikan, nol tes offline, nol keanggotaan kelompok. Tidak ada yang hilang
-- selain baris identitasnya.

-- Penjaga: kalau suatu saat ada anak semester 8 yang punya riwayat, hapus
-- berhenti di sini dan memberi tahu -- bukan menghapus diam-diam.
do $$
declare n int;
begin
  select count(*) into n
    from public.santri s
   where s.semester = 8
     and (s.auth_id is not null
       or exists (select 1 from public.penilaian   p where p.Santri_id = s.id)
       or exists (select 1 from public.kenaikan    k where k.Santri_id = s.id)
       or exists (select 1 from public.tes_offline t where t.Santri_id = s.id)
       or exists (select 1 from public.kelompok_santri ks
                   where ks.Santri_id = s.id and ks.sampai is null));

  if n > 0 then
    raise exception 'Ada % baris semester 8 yang punya riwayat. Batal dihapus.', n;
  end if;
end $$;

-- Satu per satu lewat DO, supaya penolakan berhenti di sini dengan pesan
-- yang sama seperti yang dilihat di aplikasi.
do $$
declare r record;
begin
  for r in select id from public.santri where semester = 8 loop
    perform public.hapus_santri(r.id);
  end loop;
end $$;
