<script setup>
// Perbandingan dua slide secara utuh berdampingan (tanpa potongan geser),
// ditutup interaksi "identifikasi perubahan": peserta mencentang pernyataan
// yang benar. Selesai bila semua pernyataan benar dicentang dan tidak ada
// pengecoh yang dicentang.
import { reactive, ref, computed } from 'vue'
import { getItemState, saveItemState } from '../../lib/store.js'

const props = defineProps({
  block: { type: Object, required: true },
  moduleCode: { type: String, required: true }
})

const initial = getItemState(props.moduleCode, props.block.item_key)
const picks = reactive({})
for (const s of props.block.statements) picks[s.text] = initial?.picks?.[s.text] || false
const checked = ref(initial?.done ?? false)

const correctState = computed(() =>
  props.block.statements.every(s => picks[s.text] === s.correct)
)

function toggle(text) {
  if (checked.value && correctState.value) return
  picks[text] = !picks[text]
  checked.value = false
}
function check() {
  checked.value = true
  if (correctState.value) {
    const p = {}
    for (const s of props.block.statements) p[s.text] = picks[s.text]
    saveItemState(props.moduleCode, props.block.item_key, { done: true, picks: p })
  }
}
function reset() {
  for (const s of props.block.statements) picks[s.text] = false
  checked.value = false
}
const wrongPicks = computed(() =>
  props.block.statements.filter(s => picks[s.text] && !s.correct)
)
</script>

<template>
  <section class="block interactive" :class="{ 'done-ok': checked && correctState }">
    <div class="block-head">
      <span class="chip">Demonstrasi — bandingkan, lalu identifikasi perubahannya</span>
      <span v-if="checked && correctState" class="done-note">✓ Selesai</span>
    </div>
    <p class="instruction rich" v-html="block.instruction"></p>

    <div class="pair">
      <figure class="slide">
        <div class="slide-canvas" v-html="block.beforeHtml"></div>
        <figcaption>{{ block.labelBefore }}</figcaption>
      </figure>
      <figure class="slide">
        <div class="slide-canvas" v-html="block.afterHtml"></div>
        <figcaption>{{ block.labelAfter }}</figcaption>
      </figure>
    </div>

    <p class="ask">{{ block.question }}</p>
    <div class="statements">
      <label
        v-for="s in block.statements" :key="s.text"
        class="stmt"
        :class="{ right: checked && picks[s.text] === s.correct && s.correct, wrong: checked && picks[s.text] && !s.correct }"
      >
        <input type="checkbox" :checked="picks[s.text]" @change="toggle(s.text)" />
        <span>{{ s.text }}</span>
      </label>
    </div>

    <div v-if="checked" class="feedback" :class="correctState ? 'ok' : 'no'">
      <template v-if="correctState">Tepat. {{ block.rationale }}</template>
      <template v-else>
        Belum tepat
        <template v-if="wrongPicks.length"> — kotak merah bukan perubahan yang benar.</template>
        <template v-else> — masih ada perubahan penting yang belum dicentang.</template>
        {{ block.rationale }}
      </template>
    </div>
    <div class="actions">
      <button class="btn btn-green" @click="check">Periksa</button>
      <button class="btn btn-ghost btn-small" @click="reset">Ulangi</button>
    </div>
  </section>
</template>

<style scoped>
.instruction { margin: 0 0 14px; }
.pair { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
.slide { margin: 0; }
.slide figcaption {
  margin-top: 8px; font-size: var(--fs-small); font-weight: 700;
  color: var(--ink-soft); text-align: center;
}
.ask { font-weight: 700; margin: 16px 0 8px; }
.statements { display: flex; flex-direction: column; gap: 8px; }
.stmt {
  display: flex; gap: 10px; align-items: flex-start;
  border: 1.5px solid var(--line); border-radius: var(--radius-sm);
  background: #FBFBFD; padding: 10px 12px; cursor: pointer;
  font-size: var(--fs-small); line-height: 1.45;
}
.stmt input { margin-top: 3px; accent-color: var(--bpjs-green); width: 16px; height: 16px; }
.stmt.right { border-color: var(--bpjs-green); background: var(--bpjs-green-soft); }
.stmt.wrong { border-color: var(--upn-red); background: var(--upn-red-soft); }
.actions { margin-top: 14px; display: flex; gap: 10px; }
@media (max-width: 700px) {
  .pair { grid-template-columns: 1fr; }
}
</style>
