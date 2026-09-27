-- Sorogan Digital — kembalikan priv.my_ustadz_id()
--
-- 017 men-drop public.my_ustadz_id() CASCADE lalu membuat ulang versi public
-- ber-filter role='ustadz'. Akibatnya priv.my_ustadz_id() TIDAK pernah dibuat,
-- padahal badan simpan_penilaian (005, ditulis 17/08) dan putuskan_kenaikan
-- (013) memanggilnya, dan plpgsql mengikat nama saat DIJALANKAN -- bukan saat
-- migrasi. Jadi keduanya sukses ter-apply lalu meledak di tangan ustadz.
-- Persis kelas bug yang dicatat di docs/00-project-rules.md:43 dan
-- docs/09-debug-agent.md:8.
--
-- Definisi disamakan dengan public.my_ustadz_id() (017:78): hanya role
-- 'ustadz' yang punya leger. Superadmin tidak bisa mengakses /nilai maupun
-- /kenaikan sama sekali (app/middleware/auth.ts:44), jadi tidak perlu
-- penanganan lain.

create function priv.my_ustadz_id() returns bigint
  language sql stable security definer set search_path = '' as
$$ select id from public.ustadz where auth_id = (select auth.uid()) and role = 'ustadz' $$;

-- Helper policy tidak perlu diekspos ke anon: PostgREST tidak menyentuh
-- schema priv, dan RLS hanya dievaluasi untuk role yang memang punya policy.
revoke execute on function priv.my_ustadz_id() from public;