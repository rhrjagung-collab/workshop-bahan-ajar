<script setup>
// Mengurutkan langkah/tahapan dengan tombol naik-turun (ramah ponsel).
// items pada konten = urutan yang BENAR; tampilan diacak saat dimuat.
import { ref, computed } from 'vue'
import { getItemState, saveItemState } from '../../lib/store.js'

const props = defineProps({
  block: { type: Object, required: true },
  moduleCode: { type: String, required: true }
})

function shuffleIndices(n) {
  const a = [...Array(n).keys()]
  for (let i = n - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]]
  }
  return a
}

const initial = getItemState(props.moduleCode, props.block.item_key)
const order = ref(initial?.order ? [...initial.order] : shuffleIndices(props.block.items.length))
const checked = ref(false)

const isCorrect = computed(() => order.value.every((v, i) => v === i))

function move(i, dir) {
  const j = i + dir
  if (j < 0 || j >= order.value.length) return
  const a = [...order.value];
  [a[i], a[j]] = [a[j], a[i]]
  order.value = a
  checked.value = false
}
function check() {
  checked.value = true
  if (isCorrect.value) {
    saveItemState(props.moduleCode, props.block.item_key, { done: true, order: [...order.value] })
  }
}
function reset() {
  order.value = shuffleIndices(props.block.items.length)
  checked.value = false
}
</script>

<template>
  <section class="block interactive" :class="{ 'done-ok': checked && isCorrect }">
    <div class="block-head">
      <span class="chip">Latihan — urutkan</span>
      <span v-if="checked && isCorrect" class="done-note">✓ Selesai</span>
    </div>
    <p class="instruction rich" v-html="block.instruction"></p>
    <ol class="list">
      <li v-for="(itemIdx, pos) in order" :key="itemIdx" class="item" :class="{ right: checked && itemIdx === pos, wrong: checked && itemIdx !== pos }">
        <span class="num">{{ pos + 1 }}</span>
        <span class="text">{{ block.items[itemIdx] }}</span>
        <span class="controls">
          <button class="mv" :disabled="pos === 0" @click="move(pos, -1)" aria-label="Naikkan">↑</button>
          <button class="mv" :disabled="pos === order.length - 1" @click="move(pos, 1)" aria-label="Turunkan">↓</button>
        </span>
      </li>
    </ol>
    <div v-if="checked" class="feedback" :class="isCorrect ? 'ok' : 'no'">
      <template v-if="isCorrect">Urutan tepat. {{ block.rationale }}</template>
      <template v-else>Belum tepat — gunakan tombol ↑ ↓ untuk memindahkan langkah, lalu periksa lagi.</template>
    </div>
    <div class="actions">
      <button class="btn btn-green" @click="check">Periksa</button>
      <button class="btn btn-ghost btn-small" @click="reset">Ulangi</button>
    </div>
  </section>
</template>

<style scoped>
.instruction { margin: 0 0 12px; }
.list { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 8px; }
.item {
  display: flex; align-items: center; gap: 10px;
  border: 1.5px solid var(--line); border-radius: var(--radius-sm);
  background: #FBFBFD; padding: 10px 12px;
}
.item.right { border-color: var(--bpjs-green); background: var(--bpjs-green-soft); }
.item.wrong { border-color: var(--upn-red); background: var(--upn-red-soft); }
.num {
  flex: none; width: 26px; height: 26px; border-radius: 50%;
  background: var(--bpjs-indigo); color: #fff;
  display: inline-flex; align-items: center; justify-content: center;
  font-weight: 800; font-size: 13px;
}
.text { flex: 1; }
.controls { display: flex; gap: 4px; }
.mv {
  font: inherit; font-weight: 800; width: 30px; height: 30px;
  border: 1.5px solid var(--line); border-radius: 6px;
  background: #fff; cursor: pointer; color: var(--bpjs-indigo);
}
.mv:disabled { opacity: .3; cursor: not-allowed; }
.mv:hover:not(:disabled) { border-color: var(--bpjs-indigo); }
</style>
