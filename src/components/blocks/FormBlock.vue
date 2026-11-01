<script setup>
// Lembar kerja digital (LK): tersimpan otomatis dengan debounce.
// done = semua field terisi (bisa diedit ulang kapan saja).
import { reactive, ref, watch, onMounted, onBeforeUnmount } from 'vue'
import { getItemState, saveItemState } from '../../lib/store.js'

const props = defineProps({
  block: { type: Object, required: true },
  moduleCode: { type: String, required: true }
})

const initial = getItemState(props.moduleCode, props.block.item_key)
const values = reactive({})
for (const f of props.block.fields) values[f.key] = initial?.values?.[f.key] || ''

const saveState = ref('idle') // idle | saving | saved
const done = ref(initial?.done ?? false)
let timer = null

function computeDone() {
  return props.block.fields.every(f => String(values[f.key] || '').trim().length > 0)
}

watch(values, () => {
  saveState.value = 'saving'
  done.value = computeDone()
  clearTimeout(timer)
  timer = setTimeout(persist, 700)
})

async function persist() {
  await saveItemState(props.moduleCode, props.block.item_key, {
    done: done.value, values: JSON.parse(JSON.stringify(values))
  })
  saveState.value = 'saved'
}

onBeforeUnmount(() => { clearTimeout(timer); if (saveState.value === 'saving') persist() })
</script>

<template>
  <section class="block interactive" :class="{ 'done-ok': done }">
    <div class="block-head">
      <span class="chip">{{ block.label || 'Lembar kerja' }}</span>
      <span v-if="saveState === 'saving'" class="saving">Menyimpan…</span>
      <span v-else-if="saveState === 'saved'" class="done-note">✓ Tersimpan</span>
    </div>
    <p class="instruction rich" v-html="block.instruction"></p>
    <div class="fields">
      <div v-for="f in block.fields" :key="f.key" class="field">
        <label :for="block.item_key + '-' + f.key">{{ f.label }}</label>
        <textarea
          v-if="f.type !== 'input'"
          :id="block.item_key + '-' + f.key" v-model="values[f.key]"
          :rows="f.rows || 3" :placeholder="f.placeholder"
        ></textarea>
        <input
          v-else type="text" :id="block.item_key + '-' + f.key"
          v-model="values[f.key]" :placeholder="f.placeholder"
        />
        <p v-if="f.help" class="hint">{{ f.help }}</p>
      </div>
    </div>
    <p class="hint" v-if="!done">Jawaban tersimpan otomatis saat Anda mengetik. Modul dinyatakan selesai bila semua isian terisi.</p>
  </section>
</template>

<style scoped>
.instruction { margin: 0 0 14px; }
.fields { display: flex; flex-direction: column; gap: 14px; }
.saving { font-size: 13px; color: var(--ink-faint); }
</style>
