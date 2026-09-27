# 10 — Security Agent

Menjaga satu hal di atas segalanya: **data santri adalah data anak di bawah
umur.** Itu batas keras, bukan pertimbangan (R9).

## Model ancaman nyata

| Ancaman | Penjaga |
|---|---|
| Siapa pun mendaftar lalu membaca data santri | **Pendaftaran ditutup** + RLS |
| Kunci publishable tersebar | Kunci itu memang publik; RLS yang menjaga |
| Nama ustadz diambil alih akun lain | `hubungkan_ustadz` menolak nama yang `auth_id`-nya sudah terisi |
| Ustadz mengubah nilai ustadz lain | Policy tulis dibatasi pemilik sesi |
| Nama santri bocor lewat demo/screenshot | Aturan: tidak pernah di artefak yang dibagikan |
| HP ustadz hilang sebelum antrean terkirim | Antrean lokal + bilah peringatan |

Yang **bukan** model ancamannya: serangan negara, DDoS, penyerang di jaringan
internal pesantren. Jangan bangun pertahanan untuk itu.

## Invarian yang wajib tetap benar

1. Akun yang sudah login tapi **belum terhubung** ke baris `ustadz` melihat
   **0 baris** dari tabel mana pun yang berisi data santri. Diuji, bukan
   diasumsikan — `db/016_check_hubungkan.sql`.
2. **Pendaftaran di Supabase WAJIB tertutup.** Sejak kode klaim dihapus
   (`db/015`), itulah pintu yang menjaga: penghubungan identitas hanya memilih
   nama, jadi siapa pun yang berhasil mendaftar bisa memilih nama yang belum
   terpakai. `hubungkan_ustadz` hanya mencegah pengambilalihan nama yang sudah
   dipakai, bukan pendaftaran liar.
3. Helper policy berada di schema `priv` yang tidak diekspos PostgREST.
4. Setiap tabel baru: RLS aktif **dan** policy, di migrasi yang sama.
5. RPC pengubah data pakai `SECURITY INVOKER` supaya RLS tetap penjaganya.
   `SECURITY DEFINER` hanya kalau memang harus menembus RLS, dan alasannya
   ditulis di migrasi.
6. `search_path = ''` pada semua fungsi; semua acuan berkualifikasi penuh.
7. Rahasia tidak pernah lahir dari perintah idempoten (R8).

## Kenapa `SECURITY DEFINER` pada helper policy itu wajib

`priv.is_ustadz()` membaca tabel `ustadz`, yang punya RLS. Kalau policy pada
`ustadz` memakai `is_ustadz()` sementara fungsinya `INVOKER`, evaluasinya
rekursif. `DEFINER` memutus rekursi itu. Ini bukan kelalaian — ini keharusan,
dan sudah dicatat di migrasi.

## Peringatan advisor Supabase yang disengaja

| Peringatan | Alasan tetap dibiarkan |
|---|---|
| `hubungkan_ustadz` bisa dipanggil user login | Memang tugasnya; hanya menyentuh baris yang belum terpakai |
| `putuskan_kenaikan` bisa dipanggil user login | Memang tugasnya; RLS + guard di dalamnya |
| `rls_auto_enable` ×2 | **Bukan buatan sistem ini**; event trigger bawaan project yang menyalakan RLS otomatis pada tabel baru. Guardrail bagus. Bertipe `event_trigger`, jadi tidak benar-benar bisa dipanggil lewat REST |

Peringatan **baru** di luar daftar ini wajib ditangani atau ditambahkan ke daftar
ini dengan alasannya. Jangan dibiarkan menumpuk tanpa keterangan.

## Audit rutin

```sql
-- Tabel tanpa policy
select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r' and c.relrowsecurity
  and not exists (select 1 from pg_policies p where p.tablename = c.relname);

-- Fungsi yang acuannya menunjuk schema salah
select p.proname, pg_get_functiondef(p.oid)
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname in ('public','priv');
```

Lalu `get_advisors` untuk `security` dan `performance`.

## Kebijakan rahasia

- Kunci publishable Supabase boleh ada di repo. Ia memang untuk dipublikasikan.
- Kunci `service_role` **tidak pernah** masuk repo, aplikasi, atau dokumen.
- Tidak ada lagi rahasia bersama yang perlu dibagikan ke asatidz. Kredensial
  hanya email + kata sandi masing-masing, dan itu milik mereka sendiri.

## Checklist sebelum menyerahkan

- [ ] Tabel baru: RLS + policy di migrasi yang sama
- [ ] `db/016_check_hubungkan.sql` hijau (invarian buta total masih berlaku)
- [ ] `get_advisors` tidak memunculkan peringatan baru di luar daftar
- [ ] Tidak ada nama santri di dokumen, screenshot, atau artefak yang dibagikan
- [ ] Tidak ada rahasia baru yang lahir dari perintah idempoten
- [ ] Pesan error tidak membocorkan struktur internal ke pengguna
