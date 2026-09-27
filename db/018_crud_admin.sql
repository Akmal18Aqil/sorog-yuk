-- Sorogan Digital — CRUD Admin Panel
-- Adds RLS write policies + CRUD RPC functions

-- ============================================================
-- 1. RLS Write Policies (belum ada)
-- ============================================================

-- Kelas: superadmin full CRUD
CREATE POLICY tulis_admin ON kelas FOR INSERT TO authenticated
  WITH CHECK (priv.is_superadmin());
CREATE POLICY ubah_admin ON kelas FOR UPDATE TO authenticated
  USING (priv.is_superadmin());
CREATE POLICY hapus_admin ON kelas FOR DELETE TO authenticated
  USING (priv.is_superadmin());

-- Kelompok: superadmin full CRUD
CREATE POLICY tulis_admin ON kelompok FOR INSERT TO authenticated
  WITH CHECK (priv.is_superadmin());
CREATE POLICY ubah_admin ON kelompok FOR UPDATE TO authenticated
  USING (priv.is_superadmin());
CREATE POLICY hapus_admin ON kelompok FOR DELETE TO authenticated
  USING (priv.is_superadmin());

-- Kelompok-santri: superadmin manage membership
CREATE POLICY tulis_admin ON kelompok_santri FOR INSERT TO authenticated
  WITH CHECK (priv.is_superadmin());
CREATE POLICY hapus_admin ON kelompok_santri FOR DELETE TO authenticated
  USING (priv.is_superadmin());

-- ============================================================
-- 2. RPC: Santri CRUD
-- ============================================================

CREATE FUNCTION public.tambah_santri(
  p_nama text,
  p_tingkat text DEFAULT 'BK1'
) RETURNS bigint
  LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS
$$
DECLARE v_id bigint;
BEGIN
  IF NOT priv.is_superadmin() THEN
    RAISE EXCEPTION 'Hanya superadmin yang bisa menambah santri.';
  END IF;
  INSERT INTO public.santri (nama, tingkat) VALUES (p_nama, p_tingkat)
  RETURNING id INTO v_id;
  RETURN v_id;
END
$$;

CREATE FUNCTION public.ubah_santri(
  p_id bigint,
  p_nama text,
  p_tingkat text
) RETURNS void
  LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS
$$
BEGIN
  IF NOT priv.is_superadmin() THEN
    RAISE EXCEPTION 'Hanya superadmin yang bisa mengubah santri.';
  END IF;
  UPDATE public.santri SET nama = p_nama, tingkat = p_tingkat WHERE id = p_id;
END
$$;

CREATE FUNCTION public.hapus_santri(p_id bigint) RETURNS void
  LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS
$$
BEGIN
  IF NOT priv.is_superadmin() THEN
    RAISE EXCEPTION 'Hanya superadmin yang bisa menghapus santri.';
  END IF;
  DELETE FROM public.santri WHERE id = p_id;
END
$$;

-- ============================================================
-- 3. RPC: Kelas CRUD
-- ============================================================

CREATE FUNCTION public.tambah_kelas(
  p_kode text,
  p_nama text,
  p_urutan int,
  p_ambang_online numeric DEFAULT 70,
  p_ambang_offline numeric DEFAULT 70
) RETURNS bigint
  LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS
$$
DECLARE v_id bigint;
BEGIN
  IF NOT priv.is_superadmin() THEN
    RAISE EXCEPTION 'Hanya superadmin yang bisa menambah kelas.';
  END IF;
  INSERT INTO public.kelas (kode, nama, urutan, ambang_online, ambang_offline)
  VALUES (p_kode, p_nama, p_urutan, p_ambang_online, p_ambang_offline)
  RETURNING id INTO v_id;
  RETURN v_id;
END
$$;

CREATE FUNCTION public.ubah_kelas(
  p_id bigint,
  p_kode text,
  p_nama text,
  p_urutan int,
  p_ambang_online numeric,
  p_ambang_offline numeric
) RETURNS void
  LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS
$$
BEGIN
  IF NOT priv.is_superadmin() THEN
    RAISE EXCEPTION 'Hanya superadmin yang bisa mengubah kelas.';
  END IF;
  UPDATE public.kelas
  SET kode = p_kode, nama = p_nama, urutan = p_urutan,
      ambang_online = p_ambang_online, ambang_offline = p_ambang_offline
  WHERE id = p_id;
END
$$;

CREATE FUNCTION public.hapus_kelas(p_id bigint) RETURNS void
  LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS
$$
BEGIN
  IF NOT priv.is_superadmin() THEN
    RAISE EXCEPTION 'Hanya superadmin yang bisa menghapus kelas.';
  END IF;
  DELETE FROM public.kelas WHERE id = p_id;
END
$$;

-- ============================================================
-- 4. RPC: Kelompok CRUD
-- ============================================================

CREATE FUNCTION public.tambah_kelompok(
  p_nama text,
  p_urutan int DEFAULT NULL
) RETURNS bigint
  LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS
$$
DECLARE v_id bigint;
BEGIN
  IF NOT priv.is_superadmin() THEN
    RAISE EXCEPTION 'Hanya superadmin yang bisa menambah kelompok.';
  END IF;
  INSERT INTO public.kelompok (nama, urutan) VALUES (p_nama, p_urutan)
  RETURNING id INTO v_id;
  RETURN v_id;
END
$$;

CREATE FUNCTION public.ubah_kelompok(
  p_id bigint,
  p_nama text,
  p_urutan int DEFAULT NULL
) RETURNS void
  LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS
$$
BEGIN
  IF NOT priv.is_superadmin() THEN
    RAISE EXCEPTION 'Hanya superadmin yang bisa mengubah kelompok.';
  END IF;
  UPDATE public.kelompok SET nama = p_nama, urutan = p_urutan WHERE id = p_id;
END
$$;

CREATE FUNCTION public.hapus_kelompok(p_id bigint) RETURNS void
  LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS
$$
BEGIN
  IF NOT priv.is_superadmin() THEN
    RAISE EXCEPTION 'Hanya superadmin yang bisa menghapus kelompok.';
  END IF;
  DELETE FROM public.kelompok WHERE id = p_id;
END
$$;

-- ============================================================
-- 5. RPC: Kelompok-Santri (Membership)
-- ============================================================

CREATE FUNCTION public.tambah_anggota_kelompok(
  p_kelompok_id bigint,
  p_santri_id bigint
) RETURNS void
  LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS
$$
BEGIN
  IF NOT priv.is_superadmin() THEN
    RAISE EXCEPTION 'Hanya superadmin yang bisa mengelola anggota kelompok.';
  END IF;
  INSERT INTO public.kelompok_santri (kelompok_id, santri_id)
  VALUES (p_kelompok_id, p_santri_id)
  ON CONFLICT DO NOTHING;
END
$$;

CREATE FUNCTION public.hapus_anggota_kelompok(
  p_kelompok_id bigint,
  p_santri_id bigint
) RETURNS void
  LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS
$$
BEGIN
  IF NOT priv.is_superadmin() THEN
    RAISE EXCEPTION 'Hanya superadmin yang bisa mengelola anggota kelompok.';
  END IF;
  DELETE FROM public.kelompok_santri
  WHERE kelompok_id = p_kelompok_id AND santri_id = p_santri_id;
END
$$;

-- ============================================================
-- 6. RPC: Kitab, Ibarat, Soal, Langkah — langsung via RLS
-- ============================================================
-- Tidak perlu RPC karena RLS sudah allow superadmin INSERT/UPDATE/DELETE
-- Client bisa langsung pakai sb.from('kitab').insert(...)

-- ============================================================
-- 7. Grant execute
-- ============================================================

GRANT EXECUTE ON FUNCTION public.tambah_santri(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.ubah_santri(bigint, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.hapus_santri(bigint) TO authenticated;

GRANT EXECUTE ON FUNCTION public.tambah_kelas(text, text, int, numeric, numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION public.ubah_kelas(bigint, text, text, int, numeric, numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION public.hapus_kelas(bigint) TO authenticated;

GRANT EXECUTE ON FUNCTION public.tambah_kelompok(text, int) TO authenticated;
GRANT EXECUTE ON FUNCTION public.ubah_kelompok(bigint, text, int) TO authenticated;
GRANT EXECUTE ON FUNCTION public.hapus_kelompok(bigint) TO authenticated;

GRANT EXECUTE ON FUNCTION public.tambah_anggota_kelompok(bigint, bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.hapus_anggota_kelompok(bigint, bigint) TO authenticated;
