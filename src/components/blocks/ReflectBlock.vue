<script setup>
// Refleksi singkat: satu pertanyaan terbuka, tersimpan otomatis.
import { ref, watch, onBeforeUnmount } from 'vue'
import { getItemState, saveItemState } from '../../lib/store.js'

const props = defineProps({
  block: { type: Object, required: true },
  moduleCode: { type: String, required: true }
})

const initial = getItemState(props.moduleCode, props.block.item_key)
const text = ref(initial?.text || '')
const saveState = ref('idle')
const done = ref(initial?.done ?? false)
let timer = null

watch(text, () => {
  saveState.value = 'saving'
  done.value = text.value.trim().length > 0
  clearTimeout(timer)
  timer = setTimeout(persist, 700)
})

async function persist() {
  await saveItemState(props.moduleCode, props.block.item_key, {
    done: done.value, text: text.value
  })
  saveState.value = 'saved'
}

onBeforeUnmount(() => { clearTimeout(timer); if (saveState.value === 'saving') persist() })
</script>

<template>
  <section class="block interactive" :class="{ 'done-ok': done }">
    <div class="block-head">
      <span class="chip">Refleksi</span>
      <span v-if="saveState === 'saving'" class="saving">Menyimpan…</span>
      <span v-else-if="saveState === 'saved'" class="done-note">✓ Tersimpan</span>
    </div>
    <p class="instruction rich" v-html="block.prompt"></p>
    <textarea v-model="text" rows="4" :placeholder="block.placeholder || 'Tulis refleksi Anda…'"></textarea>
  </section>
</template>

<style scoped>
.instruction { margin: 0 0 10px; }
.saving { font-size: 13px; color: var(--ink-faint); }
</style>
