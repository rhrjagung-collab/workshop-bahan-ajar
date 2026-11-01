<script setup>
// Pilihan ganda dengan umpan balik rasional (retrieval practice, low-stakes).
// done = sudah menjawab (benar atau salah) — umpan balik yang mengajarkan adalah tujuannya.
import { ref, computed } from 'vue'
import { getItemState, saveItemState, recordQuizResponse } from '../../lib/store.js'

const props = defineProps({
  block: { type: Object, required: true },
  moduleCode: { type: String, required: true }
})

const initial = getItemState(props.moduleCode, props.block.item_key)
const chosen = ref(initial?.chosen ?? null)
const answered = ref(initial?.done ?? false)
const attempt = ref(initial?.attempt ?? 0)

const isCorrect = computed(() => answered.value && chosen.value === props.block.correct)

function choose(i) {
  if (answered.value) return
  chosen.value = i
  answered.value = true
  attempt.value += 1
  const correct = i === props.block.correct
  saveItemState(props.moduleCode, props.block.item_key, {
    done: true, chosen: i, correct, attempt: attempt.value
  })
  if (props.block.quiz_kind) {
    recordQuizResponse({
      quiz_kind: props.block.quiz_kind,
      module_code: props.moduleCode,
      question_id: props.block.item_key,
      answer: props.block.options[i],
      is_correct: correct,
      attempt: attempt.value
    })
  }
}

function retry() {
  answered.value = false
  chosen.value = null
}
</script>

<template>
  <section class="block interactive" :class="{ 'done-ok': answered }">
    <div class="block-head">
      <span class="chip">Uji pemahaman</span>
      <span v-if="answered" class="done-note">✓ Terjawab</span>
    </div>
    <p class="question rich" v-html="block.question"></p>
    <div class="options">
      <button
        v-for="(opt, i) in block.options" :key="i"
        class="option"
        :class="{
          selected: chosen === i,
          right: answered && i === block.correct,
          wrong: answered && chosen === i && i !== block.correct
        }"
        @click="choose(i)"
      >
        <span class="letter">{{ 'ABCD'[i] }}</span>
        <span class="text">{{ opt }}</span>
      </button>
    </div>
    <div v-if="answered" class="feedback" :class="isCorrect ? 'ok' : 'no'">
      <strong>{{ isCorrect ? 'Benar.' : 'Belum tepat.' }}</strong>
      {{ block.rationale }}
    </div>
    <div class="actions" v-if="answered">
      <button class="btn btn-ghost btn-small" @click="retry">Jawab ulang</button>
    </div>
  </section>
</template>

<style scoped>
.question { font-weight: 600; margin: 0 0 12px; }
.options { display: flex; flex-direction: column; gap: 8px; }
.option {
  display: flex; gap: 10px; align-items: flex-start; text-align: left;
  font: inherit; color: var(--ink);
  background: #FBFBFD; border: 1.5px solid var(--line);
  border-radius: var(--radius-sm); padding: 10px 12px; cursor: pointer;
  transition: border-color .15s ease, background .15s ease;
}
.option:hover { border-color: var(--bpjs-indigo); }
.option .letter {
  flex: none; width: 26px; height: 26px; border-radius: 50%;
  background: var(--bpjs-indigo-soft); color: var(--bpjs-indigo-dark);
  display: inline-flex; align-items: center; justify-content: center;
  font-weight: 800; font-size: 13px;
}
.option.right { border-color: var(--bpjs-green); background: var(--bpjs-green-soft); }
.option.right .letter { background: var(--bpjs-green); color: #fff; }
.option.wrong { border-color: var(--upn-red); background: var(--upn-red-soft); }
.option.wrong .letter { background: var(--upn-red); color: #fff; }
</style>
