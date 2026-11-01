<script setup>
// Memasangkan konsep dengan pasangannya (dropdown, ramah ponsel).
// done = semua pasangan benar setelah "Periksa".
import { ref, computed } from 'vue'
import { getItemState, saveItemState } from '../../lib/store.js'

const props = defineProps({
  block: { type: Object, required: true },
  moduleCode: { type: String, required: true }
})

function shuffle(arr) {
  const a = [...arr]
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]]
  }
  return a
}

const initial = getItemState(props.moduleCode, props.block.item_key)
const rights = shuffle(props.block.pairs.map(p => p.right))
const chosen = ref(initial?.chosen ? { ...initial.chosen } : {})
const checked = ref(false)

const allCorrect = computed(() =>
  props.block.pairs.every((p, i) => chosen.value[i] === p.right)
)

function check() {
  checked.value = true
  if (allCorrect.value) {
    saveItemState(props.moduleCode, props.block.item_key, { done: true, chosen: { ...chosen.value } })
  }
}
function reset() {
  chosen.value = {}
  checked.value = false
}
</script>

<template>
  <section class="block interactive" :class="{ 'done-ok': checked && allCorrect }">
    <div class="block-head">
      <span class="chip">Latihan — pasangkan</span>
      <span v-if="checked && allCorrect" class="done-note">✓ Selesai</span>
    </div>
    <p class="instruction rich" v-html="block.instruction"></p>
    <div class="rows">
      <div v-for="(p, i) in block.pairs" :key="i" class="row">
        <div class="left">{{ p.left }}</div>
        <div class="arrow" aria-hidden="true">→</div>
        <div class="right">
          <select v-model="chosen[i]" :class="{ okc: checked && chosen[i] === p.right, noc: checked && chosen[i] !== p.right }">
            <option :value="undefined" disabled>— pilih —</option>
            <option v-for="r in rights" :key="r" :value="r">{{ r }}</option>
          </select>
        </div>
      </div>
    </div>
    <div v-if="checked" class="feedback" :class="allCorrect ? 'ok' : 'no'">
      <template v-if="allCorrect">Semua pasangan tepat. {{ block.rationale }}</template>
      <template v-else>Ada pasangan yang belum tepat (kotak merah). Perbaiki lalu periksa lagi.</template>
    </div>
    <div class="actions">
      <button class="btn btn-green" :disabled="Object.keys(chosen).length < block.pairs.length" @click="check">Periksa</button>
      <button class="btn btn-ghost btn-small" @click="reset">Ulangi</button>
    </div>
  </section>
</template>

<style scoped>
.instruction { margin: 0 0 12px; }
.rows { display: flex; flex-direction: column; gap: 10px; }
.row { display: flex; align-items: center; gap: 10px; }
.left {
  flex: 1; background: var(--bpjs-indigo-soft); color: var(--bpjs-indigo-dark);
  border-radius: var(--radius-sm); padding: 10px 12px; font-weight: 600; font-size: var(--fs-small);
}
.arrow { color: var(--ink-faint); }
.right { flex: 1; }
.right select { font-size: var(--fs-small); padding: 9px 10px; }
.right select.okc { border-color: var(--bpjs-green); background: var(--bpjs-green-soft); }
.right select.noc { border-color: var(--upn-red); background: var(--upn-red-soft); }
@media (max-width: 560px) {
  .row { flex-direction: column; align-items: stretch; gap: 6px; }
  .arrow { display: none; }
}
</style>
