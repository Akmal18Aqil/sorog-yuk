export default defineNuxtConfig({
  compatibilityDate: '2025-08-01',
  devtools: { enabled: true },

  // SPA, bukan SSR. Alat internal pesantren: tidak ada kebutuhan SEO, dan
  // offline-first jauh lebih mudah benar tanpa hidrasi server.
  ssr: false,

  modules: ['@nuxtjs/supabase', '@vite-pwa/nuxt'],
  css: ['~/assets/css/main.css'],

  app: {
    head: {
      htmlAttrs: { lang: 'id' },
      title: 'Sorogan Digital',
      meta: [
        { name: 'viewport', content: 'width=device-width, initial-scale=1, viewport-fit=cover' },
        { name: 'theme-color', content: '#25543f' },
      ],
    },

    // Tanpa transisi, pindah nav terasa seperti refresh: halaman lama hilang
    // seketika, lalu yang baru muncul setelah `onMounted` selesai ambil data.
    // Mata membaca jeda itu sebagai "halaman dimuat ulang", bukan "pindah
    // halaman". `.page-*` di main.css yang mengatur ini.
    //
    // `appear` dimatikan supaya muat PERTAMA tidak ikut memudar -- kalau ikut,
    // setiap Kali app dibuka terlihat seperti sedang memuat.
    pageTransition: { name: 'page', mode: 'out-in', appear: false },
  },

  supabase: {
    url: process.env.SUPABASE_URL || 'https://unozvswlxqbhqzmlsirl.supabase.co',
    // Kunci publishable memang untuk dipublikasikan; yang menjaga data adalah
    // RLS dan kode klaim ustadz, bukan kerahasiaan kunci ini.
    key: process.env.SUPABASE_KEY || 'sb_publishable_pflSel-WXV5KN7gJsdaZsw_C93xwrof',
    // Pengalihan diurus middleware sendiri: ustadz yang sudah login tapi belum
    // klaim kode butuh perlakuan berbeda dari yang belum login sama sekali.
    redirect: false,
    // Tipe dibangkitkan dari skema dan dipakai bersama domain, jadi letaknya
    // di shared/ — bukan di lokasi bawaan modul.
    types: '~~/shared/types/database.ts',
  },

  pwa: {
    registerType: 'autoUpdate',
    manifest: {
      name: 'Sorogan Digital',
      short_name: 'Sorogan',
      description: 'Leger tes lisan baca kitab — BK 1 & BK 2',
      lang: 'id',
      start_url: '/',
      display: 'standalone',
      orientation: 'portrait',
      background_color: '#faf8f4',
      theme_color: '#25543f',
      icons: [{ src: '/icon.svg', sizes: 'any', type: 'image/svg+xml', purpose: 'any maskable' }],
    },
    workbox: {
      // Hanya aset build yang di-precache. Panggilan Supabase TIDAK PERNAH
      // di-cache: nilai basi yang tampil seolah baru jauh lebih berbahaya
      // daripada pesan gagal yang jujur.
      globPatterns: ['**/*.{js,css,html,svg,ico,woff2}'],
      navigateFallback: '/',
    },
    client: { installPrompt: true },
    devOptions: { enabled: false },
  },

  typescript: { typeCheck: false, strict: true },
})
