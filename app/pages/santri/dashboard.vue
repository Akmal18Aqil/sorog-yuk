<script setup lang="ts">
import type { Database } from '#shared/types/database'

definePageMeta({ middleware: 'auth' })

const sb = useSupabaseClient<Database>()
const pengguna = useSupabaseUser()
const { keluar } = useAuth()

const santri = ref<{ id: number; nama: string; tingkat: string } | null>(null)
const nilai = ref<{ sesi_id: number | null; jml_soal: number | null; nilai: number | null }[]>([])
const galat = ref('')

onMounted(async () => {
  if (!pengguna.value) return
  try {
    // Ambil data santri
    const { data: s, error: e1 } = await sb.from('santri')
      .select('id, nama, tingkat')
      .eq('auth_id', pengguna.value.id)
      .maybeSingle()
    if (e1) throw new Error(e1.message)
    santri.value = s

    if (s) {
      // Ambil nilai
      const { data: n, error: e2 } = await sb.from('v_nilai_santri')
        .select('*')
        .eq('santri_id', s.id)
        .order('sesi_id', { ascending: false })
      if (e2) throw new Error(e2.message)
      nilai.value = n ?? []
    }
  }
  catch (e) { galat.value = (e as Error).message }
})

function formatNilai(v: number | null): string {
  return v != null ? v.toFixed(1) : '-'
}
</script>

<template>
  <div class="wadah">
    <div class="bilah">
      <div>
        <h1 style="margin: 0">{{ santri?.nama ?? 'Santri' }}</h1>
        <p class="redup" style="margin: 0">{{ santri?.tingkat }}</p>
      </div>
      <button class="kecil hanya-hp" @click="keluar">Keluar</button>
    </div>

    <p v-if="galat" class="galat">{{ galat }}</p>

    <h2>Nilai Saya</h2>
    <div v-if="nilai.length">
      <table>
        <thead>
          <tr>
            <th>No</th>
            <th>Jumlah Soal</th>
            <th>Nilai</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(n, i) in nilai" :key="i">
            <td>{{ i + 1 }}</td>
            <td>{{ n.jml_soal ?? '-' }}</td>
            <td :style="{ fontWeight: 600, color: (n.nilai ?? 0) >= 70 ? 'var(--benar)' : 'var(--salah)' }">
              {{ formatNilai(n.nilai) }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <p v-else class="redup" style="text-align: center">Belum ada nilai.</p>
  </div>
</template>
