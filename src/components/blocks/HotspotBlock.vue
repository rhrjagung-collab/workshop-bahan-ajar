<script setup>
// Diagram berlabel interaktif: klik penanda bernomor untuk membuka penjelasan.
// done = semua penanda pernah dibuka.
import { ref, computed } from 'vue'
import { getItemState, saveItemState } from '../../lib/store.js'

const props = defineProps({
  block: { type: Object, required: true },
  moduleCode: { type: String, required: true }
})

const initial = getItemState(props.moduleCode, props.block.item_key)
const opened = ref(initial?.opened ? [...initial.opened] : [])
const active = ref(null)

const allOpened = computed(() => opened.value.length >= props.block.hotspots.length)

function open(i) {
  active.value = i
  if (!opened.value.includes(i)) {
    opened.value.push(i)
    if (allOpened.value) {
      saveItemState(props.moduleCode, props.block.item_key, { done: true, opened: [...opened.value] })
    } else {
      saveItemState(props.moduleCode, props.block.item_key, { done: false, opened: [...opened.value] })
    }
  }
}
</script>

<template>
  <section class="block interactive" :class="{ 'done-ok': allOpened }">
    <div class="block-head">
      <span class="chip">Jelajahi — klik penanda</span>
      <span v-if="allOpened" class="done-note">✓ Semua dibuka</span>
    </div>
    <p class="instruction rich" v-html="block.instruction"></p>
    <div class="stage" :style="{ aspectRatio: block.aspect || '16 / 9' }">
      <img :src="block.image" :alt="block.alt" />
      <button
        v-for="(h, i) in block.hotspots" :key="i"
        class="spot" :class="{ open: opened.includes(i) }"
        :style="{ left: h.x + '%', top: h.y + '%' }"
        :aria-label="'Penjelasan: ' + h.label"
        @click="open(i)"
      >{{ i + 1 }}</button>
    </div>
    <div v-if="active !== null" class="detail">
      <p class="detail-label">{{ block.hotspots[active].label }}</p>
      <p class="detail-text">{{ block.hotspots[active].text }}</p>
    </div>
    <p class="hint">{{ opened.length }} dari {{ block.hotspots.length }} penanda dibuka.</p>
  </section>
</template>

<style scoped>
.instruction { margin: 0 0 12px; }
.stage { position: relative; border: 1px solid var(--line); border-radius: var(--radius); overflow: hidden; background: #fff; }
.stage img { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: contain; }
.spot {
  position: absolute; transform: translate(-50%, -50%);
  width: 30px; height: 30px; border-radius: 50%;
  border: 2px solid #fff; background: var(--bpjs-indigo); color: #fff;
  font: inherit; font-weight: 800; font-size: 13px;
  cursor: pointer; box-shadow: 0 2px 6px rgba(0,0,0,.35);
}
.spot.open { background: var(--bpjs-green); }
.spot:hover { filter: brightness(1.15); }
.detail {
  margin-top: 12px; padding: 12px 14px;
  background: var(--bpjs-indigo-soft); border-radius: var(--radius-sm);
}
.detail-label { margin: 0 0 4px; font-weight: 800; color: var(--bpjs-indigo-dark); }
.detail-text { margin: 0; font-size: var(--fs-small); }
</style>
