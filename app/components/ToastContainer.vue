<script setup lang="ts">
const { toasts, dismiss } = useToast()
</script>

<template>
  <Teleport to="body">
    <div class="toast-container">
      <TransitionGroup name="toast">
        <div
          v-for="t in toasts" :key="t.id"
          class="toast"
          :class="`toast-${t.type}`"
          @click="dismiss(t.id)"
        >
          {{ t.message }}
        </div>
      </TransitionGroup>
    </div>
  </Teleport>
</template>

<style scoped>
.toast-container {
  position: fixed; top: var(--space-4); right: var(--space-4); z-index: 200;
  display: flex; flex-direction: column; gap: var(--space-2); max-width: 320px;
}
.toast {
  padding: var(--space-3) var(--space-4);
  border-radius: var(--radius-md);
  font-size: var(--text-sm); font-weight: 500;
  cursor: pointer; box-shadow: var(--shadow-lg);
  animation: slideIn 0.2s ease;
}
.toast-success { background: var(--success); color: var(--teks-aksen); }
.toast-error { background: var(--error); color: var(--teks-aksen); }
.toast-info { background: var(--primary); color: var(--teks-aksen); }

.toast-enter-active { animation: slideIn 0.2s ease; }
.toast-leave-active { animation: slideOut 0.2s ease; }
@keyframes slideIn { from { transform: translateX(100%); opacity: 0; } }
@keyframes slideOut { to { transform: translateX(100%); opacity: 0; } }
</style>
