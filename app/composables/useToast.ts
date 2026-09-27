/**
 * Toast notification composable.
 * Simple, mobile-friendly notification system.
 */
interface Toast {
  id: number
  message: string
  type: 'success' | 'error' | 'info'
}

let nextId = 0

export function useToast() {
  const toasts = useState<Toast[]>('toasts', () => [])

  function add(message: string, type: Toast['type'] = 'info') {
    const id = nextId++
    toasts.value.push({ id, message, type })
    setTimeout(() => dismiss(id), 3000)
  }

  function dismiss(id: number) {
    toasts.value = toasts.value.filter(t => t.id !== id)
  }

  return {
    toasts,
    success: (msg: string) => add(msg, 'success'),
    error: (msg: string) => add(msg, 'error'),
    info: (msg: string) => add(msg, 'info'),
    dismiss,
  }
}
