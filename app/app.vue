<script setup lang="ts">
import { perluSidebar, halamanSendiri } from '~/utils/nav'

const { init } = useTheme()
const { role } = useAuth()
const lebar = useLebar()
const route = useRoute()

const tampilSidebar = computed(() => perluSidebar(route.path, role.value, lebar.value))
// BottomNav sendiri yang mengecek apakah role-nya punya item. Di sini hanya
// soal rute: halaman yang berdiri sendiri tidak boleh punya navigasi apa pun.
const tampilNavBawah = computed(() => !halamanSendiri(route.path))

onMounted(() => {
  init()
})
</script>

<template>
  <div class="app-shell">
    <Sidebar v-if="tampilSidebar" />
    <div class="app-main">
      <NuxtPage />
    </div>
  </div>
  <BottomNav v-if="tampilNavBawah" />
  <BilahAntrean />
  <ToastContainer />
</template>
