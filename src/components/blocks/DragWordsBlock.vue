<script setup>
// Isi bagian kalimat yang rumpang dengan kata dari bank (sentuh, ramah ponsel).
// done = semua slot terisi benar setelah tombol "Periksa".
import { ref, computed } from 'vue'
import { getItemState, saveItemState } from '../../lib/store.js'

const props = defineProps({
  block: { type: Object, required: true },
  moduleCode: { type: String, required: true }
})

// Urutan kata di bank diacak sekali per sesi.
function shuffle(arr) {
  const a = [...arr]
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]]
  }
  return a
}

const initial = getItemState(props.moduleCode, props.block.item_key)

// Parsing teks "… [[kata]] …" menjadi segmen teks & slot.
const parts = (() => {
  const segs = []
  let last = 0
  const re = /\[\[(.+?)\]\]/g
  let m
  while ((m = re.exec(props.block.text)) !== null) {
    if (m.index > last) segs.push({ t: 'text', s: props.block.text.slice(last, m.index) })
    segs.push({ t: 'slot' })
    last = m.index + m[0].length
  }
  if (last < props.block.text.length) segs.push({ t: 'text', s: props.block.text.slice(last) })
  return segs
})()

const slotCount = parts.filter(p => p.t === 'slot').length
const placed = ref(initial?.placed ? [...initial.placed] : Array(slotCount).fill(null))
const checked = ref(false)
const bank = ref(initial?.done ? [] : shuffle(props.block.options))
const selectedWord = ref(null)

let slotIndex = -1
const segments = parts.map(p => {
  if (p.t === 'slot') { slotIndex++; return { ...p, idx: slotIndex } }
  return p
})

const allFilled = computed(() => placed.value.every(v => v !== null))
const allCorrect = computed(() =>
  placed.value.every((w, i) => w === props.block.answers[i])
)

function pickBank(word) {
  selectedWord.value = selectedWord.value === word ? null : word
}
function fillSlot(idx) {
  if (checked.value && allCorrect.value) return
  if (placed.value[idx]) {
    // keluarkan kata dari slot
    bank.value.push(placed.value[idx])
    placed.value[idx] = null
    checked.value = false
    return
  }
  if (selectedWord.value) {
    placed.value[idx] = selectedWord.value
    bank.value = bank.value.filter(w => w !== selectedWord.value)
    selectedWord.value = null
    checked.value = false
  }
}
function check() {
  checked.value = true
  if (allCorrect.value) {
    saveItemState(props.moduleCode, props.block.item_key, { done: true, placed: [...placed.value] })
  }
}
function reset() {
  placed.value = Array(slotCount).fill(null)
  bank.value = shuffle(props.block.options)
  checked.value = false
}
</script>

<template>
  <section class="block interactive" :class="{ 'done-ok': checked && allCorrect }">
    <div class="block-head">
      <span class="chip">Latihan — isi bagian rumpang</span>
      <span v-if="checked && allCorrect" class="done-note">✓ Selesai</span>
    </div>
    <p class="instruction rich" v-html="block.instruction"></p>
    <p class="sentence">
      <template v-for="(seg, i) in segments" :key="i">
        <span v-if="seg.t === 'text'">{{ seg.s }}</span>
        <button
          v-else
          class="slot"
          :class="{
            filled: placed[seg.idx],
            right: checked && placed[seg.idx] === block.answers[seg.idx],
            wrong: checked && placed[seg.idx] !== block.answers[seg.idx]
          }"
          @click="fillSlot(seg.idx)"
        >{{ placed[seg.idx] || '____' }}</button>
      </template>
    </p>
    <div class="bank" aria-label="Bank kata">
      <button
        v-for="w in bank" :key="w"
        class="word" :class="{ selected: selectedWord === w }"
        @click="pickBank(w)"
      >{{ w }}</button>
    </div>
    <div v-if="checked" class="feedback" :class="allCorrect ? 'ok' : 'no'">
      <template v-if="allCorrect">Benar semua. {{ block.rationale }}</template>
      <template v-else>Belum semua tepat — slot merah perlu diperbaiki. Klik slot untuk mengeluarkan kata.</template>
    </div>
    <div class="actions">
      <button class="btn btn-green" :disabled="!allFilled" @click="check">Periksa</button>
      <button class="btn btn-ghost btn-small" @click="reset">Ulangi</button>
    </div>
  </section>
</template>

<style scoped>
.instruction { margin: 0 0 12px; }
.sentence { line-height: 2.3; margin: 0 0 14px; }
.slot {
  font: inherit; font-weight: 700; color: var(--bpjs-indigo-dark);
  border: 1.5px dashed var(--bpjs-indigo); border-radius: 6px;
  background: var(--bpjs-indigo-soft);
  padding: 3px 12px; margin: 0 3px; cursor: pointer; min-width: 90px;
}
.slot.filled { border-style: solid; background: #fff; }
.slot.right { border-color: var(--bpjs-green); background: var(--bpjs-green-soft); }
.slot.wrong { border-color: var(--upn-red); background: var(--upn-red-soft); }
.bank { display: flex; flex-wrap: wrap; gap: 8px; }
.word {
  font: inherit; font-weight: 600;
  border: 1.5px solid var(--line); background: #FBFBFD;
  border-radius: 999px; padding: 6px 14px; cursor: pointer;
}
.word.selected { border-color: var(--bpjs-green); background: var(--bpjs-green-soft); }
</style>
