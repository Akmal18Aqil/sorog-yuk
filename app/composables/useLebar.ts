/**
 * Shell mana yang sedang dipakai: true berarti lebar (>= 900px).
 *
 * Sidebar membaca nilai ini untuk deciding boleh tampil atau tidak.
 * BottomNav tidak: ia selalu ada di DOM lalu disembunyikan oleh CSS
 * `@media (min-width: 900px)`, supaya tidak ikut hilang saat pindah halaman
 * dan tidak perlu di-mount ulang tiap navigasi.
 *
 * Ambang 900px bukan "ukuran iPad". Di bawah 900 navigasi bawah masih dalam
 * jangkauan jari; di atas itu tangan sedang memegang pena, bukan HP.
 */
const AMBANG = '(min-width: 900px)'

export function useLebar() {
  const lebar = useState('lebar', () => false)
  let mq: MediaQueryList | null = null

  function terapkan(e: MediaQueryListEvent) { lebar.value = e.matches }

  onMounted(() => {
    mq = window.matchMedia(AMBANG)
    lebar.value = mq.matches
    mq.addEventListener('change', terapkan)
  })

  onBeforeUnmount(() => mq?.removeEventListener('change', terapkan))

  return lebar
}
