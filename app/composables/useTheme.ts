/**
 * Theme composable — light/dark mode toggle.
 * Uses localStorage + class on <html> for manual control.
 * Falls back to system preference if no saved choice.
 */
export function useTheme() {
  const theme = useState<'light' | 'dark'>('theme', () => 'light')

  function apply(t: 'light' | 'dark') {
    document.documentElement.classList.toggle('dark', t === 'dark')
    theme.value = t
    localStorage.setItem('sorogan.theme', t)
  }

  function toggle() {
    apply(theme.value === 'light' ? 'dark' : 'light')
  }

  /** Initialize on client: read localStorage or system preference. */
  function init() {
    const saved = localStorage.getItem('sorogan.theme') as 'light' | 'dark' | null
    if (saved) {
      apply(saved)
    } else {
      const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
      apply(prefersDark ? 'dark' : 'light')
    }
  }

  return { theme, toggle, init }
}
