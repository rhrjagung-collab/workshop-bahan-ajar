<script setup>
// Kuis penutup modul / pre-test / ujian akhir.
// passScore null  -> diagnostik (tanpa nilai lulus; selesai setelah mengirim).
// passScore 0-100 -> harus mencapai nilai minimal; boleh diulang (low-stakes).
import { ref, computed, reactive } from 'vue'
import { getItemState, saveItemState, recordQuizResponse } from '../../lib/store.js'

const props = defineProps({
  block: { type: Object, required: true },
  moduleCode: { type: String, required: true }
})

const initial = getItemState(props.moduleCode, props.block.item_key)
const answers = reactive({})
const submitted = ref(false)
const attempt = ref(initial?.attempt ?? 0)
const score = ref(initial?.score ?? null)
const passed = ref(initial?.done ?? false)
const reviewOpen = ref(false)

// Pulihkan jawaban sebelumnya bila ada
if (initial?.answers) Object.assign(answers, initial.answers)
if (initial?.done) submitted.value = true

const allAnswered = computed(() => props.block.questions.every(q => answers[q.id] !== undefined))

const computedScore = computed(() => {
  const n = props.block.questions.length
  const correct = props.block.questions.filter(q => answers[q.id] === q.correct).length
  return Math.round((correct / n) * 100)
})

function submit() {
  submitted.value = true
  attempt.value += 1
  score.value = computedScore.value
  const pass = props.block.passScore == null ? true : score.value >= props.block.passScore
  passed.value = pass
  saveItemState(props.moduleCode, props.block.item_key, {
    done: pass, score: score.value, attempt: attempt.value,
    answers: JSON.parse(JSON.stringify(answers))
  })
  props.block.questions.forEach(q => {
    recordQuizResponse({
      quiz_kind: props.block.quiz_kind || 'modul',
      module_code: props.moduleCode,
      question_id: q.id,
      answer: q.options[answers[q.id]],
      is_correct: answers[q.id] === q.correct,
      attempt: attempt.value
    })
  })
}

function retry() {
  Object.keys(answers).forEach(k => delete answers[k])
  submitted.value = false
  reviewOpen.value = false
}
</script>

<template>
  <section class="block interactive quizgate" :class="{ 'done-ok': passed }">
    <div class="block-head">
      <span class="chip">{{ block.label || 'Kuis modul' }}</span>
      <span v-if="passed" class="done-note">✓ Lulus</span>
    </div>
    <p class="instruction rich" v-html="block.instruction"></p>

    <div v-if="submitted && !reviewOpen" class="summary">
      <template v-if="block.passScore == null">
        <p class="big">Terima kasih — jawaban Anda terkirim.</p>
        <p>Jawaban ini menjadi data awal (baseline) untuk tim fasilitator. Tidak ada nilai lulus; jawab sesuai kondisi Anda saat ini.</p>
      </template>
      <template v-else-if="passed">
        <p class="big okc">Nilai Anda: {{ score }} / 100</p>
        <p>Syarat kelulusan {{ block.passScore }} terpenuhi. Lanjutkan ke bagian berikutnya.</p>
      </template>
      <template v-else>
        <p class="big noc">Nilai Anda: {{ score }} / 100 — belum mencapai {{ block.passScore }}.</p>
        <p>Tidak apa-apa: tinjau umpan balik, pelajari kembali bagian terkait, lalu coba lagi.</p>
      </template>
      <div class="actions">
        <button class="btn btn-ghost btn-small" @click="reviewOpen = true">Tinjau umpan balik</button>
        <button v-if="block.passScore != null && !passed" class="btn btn-primary btn-small" @click="retry">Coba lagi</button>
      </div>
    </div>

    <div v-else class="questions">
      <div v-for="(q, qi) in block.questions" :key="q.id" class="q">
        <p class="q-text"><span class="q-num">{{ qi + 1 }}.</span> <span v-html="q.question"></span></p>
        <div class="q-options">
          <button
            v-for="(opt, i) in q.options" :key="i"
            class="option"
            :class="{
              selected: answers[q.id] === i,
              right: submitted && i === q.correct,
              wrong: submitted && answers[q.id] === i && i !== q.correct
            }"
            :disabled="submitted"
            @click="answers[q.id] = i"
          >
            <span class="letter">{{ 'ABCD'[i] }}</span>
            <span>{{ opt }}</span>
          </button>
        </div>
        <p v-if="submitted" class="rationale" :class="answers[q.id] === q.correct ? 'ok' : 'no'">
          <strong>{{ answers[q.id] === q.correct ? 'Benar.' : 'Belum tepat.' }}</strong>
          {{ q.rationale }}
        </p>
      </div>
      <div class="actions">
        <button v-if="!submitted" class="btn btn-green" :disabled="!allAnswered" @click="submit">
          {{ block.passScore == null ? 'Kirim jawaban' : 'Kirim & lihat nilai' }}
        </button>
        <button v-else class="btn btn-ghost btn-small" @click="reviewOpen = false">Sembunyikan tinjauan</button>
        <p v-if="!submitted" class="hint">
          {{ block.passScore == null
            ? 'Diagnostik awal — tidak memengaruhi kelulusan.'
            : 'Nilai minimal lulus: ' + block.passScore + '. Boleh diulang.' }}
        </p>
      </div>
    </div>
  </section>
</template>

<style scoped>
.instruction { margin: 0 0 14px; }
.big { font-size: var(--fs-h3); font-weight: 800; margin: 0 0 6px; }
.okc { color: var(--bpjs-green-dark); }
.noc { color: var(--upn-red); }
.questions { display: flex; flex-direction: column; gap: 22px; }
.q-text { font-weight: 600; margin: 0 0 8px; }
.q-num { color: var(--bpjs-indigo); font-weight: 800; }
.q-options { display: flex; flex-direction: column; gap: 6px; }
.option {
  display: flex; gap: 10px; align-items: flex-start; text-align: left;
  font: inherit; color: var(--ink);
  background: #FBFBFD; border: 1.5px solid var(--line);
  border-radius: var(--radius-sm); padding: 9px 12px; cursor: pointer;
}
.option:disabled { cursor: default; }
.option.selected { border-color: var(--bpjs-indigo); background: var(--bpjs-indigo-soft); }
.option.right { border-color: var(--bpjs-green); background: var(--bpjs-green-soft); }
.option.wrong { border-color: var(--upn-red); background: var(--upn-red-soft); }
.letter {
  flex: none; width: 24px; height: 24px; border-radius: 50%;
  background: var(--bpjs-indigo-soft); color: var(--bpjs-indigo-dark);
  display: inline-flex; align-items: center; justify-content: center;
  font-weight: 800; font-size: 12.5px;
}
.rationale { font-size: var(--fs-small); padding: 10px 12px; border-radius: var(--radius-sm); margin: 8px 0 0; }
.rationale.ok { background: var(--bpjs-green-soft); color: var(--bpjs-green-dark); }
.rationale.no { background: var(--upn-red-soft); color: var(--upn-red); }
</style>
