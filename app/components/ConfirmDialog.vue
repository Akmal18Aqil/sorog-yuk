<script setup lang="ts">
defineProps<{
  visible: boolean
  message: string
  confirmText?: string
}>()

defineEmits<{
  confirm: []
  cancel: []
}>()
</script>

<template>
  <Teleport to="body">
    <Transition name="fade">
      <div v-if="visible" class="overlay" @click.self="$emit('cancel')">
        <div class="modal">
          <p style="margin: 0; font-size: var(--text-base)">{{ message }}</p>
          <div class="baris mt-4">
            <button style="flex: 1" @click="$emit('cancel')">Batal</button>
            <button class="utama" style="flex: 1; background: var(--error); border-color: var(--error)" @click="$emit('confirm')">
              {{ confirmText || 'Ya, Hapus' }}
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>
