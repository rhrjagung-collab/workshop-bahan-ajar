<script setup>
// Pembanding geser sebelum/sesudah untuk demonstrasi perbaikan slide.
// done = peserta pernah menggeser pembanding (interaksi diamati).
import { ref } from 'vue'
import { getItemState, saveItemState } from '../../lib/store.js'

const props = defineProps({
  block: { type: Object, required: true },
  moduleCode: { type: String, required: true }
})

const initial = getItemState(props.moduleCode, props.block.item_key)
const pos = ref(initial?.pos ?? 50)
const touched = ref(initial?.done ?? false)

function onSlide(e) {
  pos.value = Number(e.target.value)
  if (!touched.value) {
    touched.value = true
    saveItemState(props.moduleCode, props.block.item_key, { done: true, pos: pos.value })
  }
}
</script>

<template>
  <section class="block interactive ba" :class="{ 'done-ok': touched }">
    <div class="block-head">
      <span class="chip">Demonstrasi — geser untuk membandingkan</span>
      <span v-if="touched" class="done-note">✓ Ditinjau</span>
    </div>
    <p class="instruction rich" v-html="block.instruction"></p>
    <div class="stage slide-canvas">
      <div class="panel before" v-html="block.beforeHtml"></div>
      <div class="panel after" :style="{ clipPath: `inset(0 0 0 ${pos}%)` }" v-html="block.afterHtml"></div>
      <div class="divider" :style="{ left: pos + '%' }"></div>
      <span class="tag tag-before">{{ block.labelBefore || 'Sebelum' }}</span>
      <span class="tag tag-after">{{ block.labelAfter || 'Sesudah' }}</span>
    </div>
    <input
      class="slider" type="range" min="0" max="100" :value="pos"
      @input="onSlide" :aria-label="'Pembanding sebelum-sesudah, posisi ' + pos + ' persen'"
    />
    <p class="hint">{{ block.rationale }}</p>
  </section>
</template>

<style scoped>
.instruction { margin: 0 0 12px; }
.stage { position: relative; }
.panel { position: absolute; inset: 0; padding: 14px 18px; overflow: hidden; }
.panel.before { position: relative; background: #fff; color: var(--ink); }
.panel.after { background: var(--bpjs-indigo); color: #fff; }
.divider {
  position: absolute; top: 0; bottom: 0; width: 3px;
  background: var(--upn-gold); pointer-events: none;
}
.tag {
  position: absolute; bottom: 8px; font-size: 11.5px; font-weight: 800;
  padding: 2px 10px; border-radius: 999px; letter-spacing: .04em;
}
.tag-before { left: 8px; background: #ECEEF2; color: var(--ink-soft); }
.tag-after { right: 8px; background: var(--upn-gold); color: var(--bpjs-indigo-dark); }
.slider {
  width: 100%; margin-top: 14px;
  accent-color: var(--bpjs-green);
}
</style>
