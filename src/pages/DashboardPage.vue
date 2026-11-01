<script setup>
// Dashboard fasilitator/narasumber: kelengkapan per peserta, agregat per modul,
// soal tersulit, dan ekspor CSV.
import { ref, computed, onMounted } from 'vue'
import { backend } from '../lib/backend.js'
import { modules } from '../lib/course.js'
import { isFacilitator, store } from '../lib/store.js'
import { go } from '../lib/router.js'

const data = ref(null)
const err = ref('')
const loading = ref(true)

if (!store.session) go('/login')

async function refresh() {
  loading.value = true
  err.value = ''
  try {
    data.value = await backend.loadDashboard()
  } catch (e) {
    err.value = e.message
  } finally {
    loading.value = false
  }
}

onMounted(refresh)

// Matriks peserta x modul
const rows = computed(() => {
  if (!data.value) return []
  const modMap = {}
  for (const r of data.value.modules) {
    modMap[r.participant_id + '|' + r.module_code] = r
  }
  return data.value.participants.map(p => {
    const cells = modules.map(m => modMap[p.id + '|' + m.code])
    const doneCount = cells.filter(c => c?.status === 'selesai').length
    return {
      p,
      cells,
      doneCount,
      percent: Math.round((doneCount / modules.length) * 100)
    }
  }).sort((a, b) => b.percent - a.percent)
})

// Rata-rata penyelesaian per modul
const perModule = computed(() => {
  if (!data.value) return []
  const n = data.value.participants.length || 1
  return modules.map(m => {
    const doneCount = data.value.modules.filter(r => r.module_code === m.code && r.status === 'selesai').length
    const started = data.value.modules.filter(r => r.module_code === m.code && r.status !== 'belum' && r.status !== undefined).length
    return { ...m, donePct: Math.round((doneCount / n) * 100), startedPct: Math.round((started / n) * 100) }
  })
})

// Soal dengan tingkat kesalahan tertinggi
const hardest = computed(() => {
  if (!data.value) return []
  const agg = {}
  for (const r of data.value.quiz) {
    if (r.quiz_kind === 'pre' || r.quiz_kind === 'akhir') continue
    const k = r.module_code + '|' + r.question_id
    agg[k] = agg[k] || { key: k, module_code: r.module_code, question_id: r.question_id, n: 0, wrong: 0 }
    agg[k].n += 1
    if (r.is_correct === false) agg[k].wrong += 1
  }
  return Object.values(agg)
    .filter(a => a.n >= 2)
    .map(a => ({ ...a, wrongPct: Math.round((a.wrong / a.n) * 100) }))
    .sort((a, b) => b.wrongPct - a.wrongPct)
    .slice(0, 10)
})

function downloadCsv(name, rows) {
  const csv = rows.map(r => r.map(c => `"${String(c ?? '').replaceAll('"', '""')}"`).join(';')).join('\n')
  const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8' })
  const a = document.createElement('a')
  a.href = URL.createObjectURL(blob)
  a.download = name
  a.click()
  URL.revokeObjectURL(a.href)
}

function exportMatrix() {
  const header = ['Nama', 'Email', 'Kelompok', ...modules.map(m => m.code.toUpperCase() + ' %'), ...modules.map(m => m.code.toUpperCase() + ' status'), 'Total %']
  const body = rows.value.map(r => [
    r.p.nama, r.p.email, r.p.kelompok,
    ...r.cells.map(c => c?.percent ?? 0),
    ...r.cells.map(c => c?.status ?? 'belum'),
    r.percent
  ])
  downloadCsv('dashboard-kelengkapan.csv', [header, ...body])
}

function exportQuiz() {
  const header = ['Waktu', 'Email', 'Jenis kuis', 'Modul', 'Soal', 'Jawaban', 'Benar', 'Percobaan']
  const byEmail = Object.fromEntries(data.value.participants.map(p => [p.id, p.email]))
  const body = data.value.quiz.map(q => [
    q.created_at, byEmail[q.participant_id] || q.participant_id, q.quiz_kind,
    q.module_code, q.question_id, q.answer, q.is_correct ? '1' : '0', q.attempt
  ])
  downloadCsv('respons-kuis.csv', [header, ...body])
}
</script>

<template>
  <div class="dash">
    <div v-if="!isFacilitator && !loading" class="card warn-card">
      <h1>Akses terbatas</h1>
      <p>Dashboard hanya untuk fasilitator, narasumber, dan administrasi. Peran Anda saat ini: <strong>{{ store.session?.peran }}</strong>.</p>
      <a class="btn btn-ghost" href="#/">Kembali</a>
    </div>

    <template v-else>
      <div class="card head-card">
        <h1>Dashboard fasilitator</h1>
        <p class="muted">Kelengkapan modul peserta sebelum workshop 9–10 November 2026. Data diperbarui otomatis setiap kali peserta menyelesaikan aktivitas.</p>
        <div class="actions">
          <button class="btn btn-primary btn-small" @click="exportMatrix">Ekspor kelengkapan (CSV)</button>
          <button class="btn btn-ghost btn-small" @click="exportQuiz">Ekspor respons kuis (CSV)</button>
          <button class="btn btn-ghost btn-small" @click="refresh">Muat ulang</button>
        </div>
      </div>

      <div v-if="err" class="card error-card">{{ err }}</div>
      <div v-if="loading && !data" class="card">Memuat data…</div>

      <template v-if="data">
        <section class="card">
          <h2>Penyelesaian per modul ({{ data.participants.length }} peserta)</h2>
          <div class="mod-grid">
            <div v-for="m in perModule" :key="m.code" class="mod-cell">
              <div class="mod-code">{{ m.code.toUpperCase() }}</div>
              <div class="bar"><div class="fill done" :style="{ width: m.donePct + '%' }"></div></div>
              <p>{{ m.donePct }}% selesai • {{ m.startedPct }}% dimulai</p>
            </div>
          </div>
        </section>

        <section class="card">
          <h2>Matriks peserta</h2>
          <div class="scroll">
            <table class="table">
              <thead>
                <tr>
                  <th>Peserta</th><th>Kelompok</th>
                  <th v-for="m in modules" :key="m.code">{{ m.code.toUpperCase() }}</th>
                  <th>Total</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="r in rows" :key="r.p.id">
                  <td><strong>{{ r.p.nama }}</strong><br /><span class="muted">{{ r.p.email }}</span></td>
                  <td>{{ r.p.kelompok }}</td>
                  <td v-for="(c, i) in r.cells" :key="i">
                    <span class="dot" :class="'st-' + (c?.status || 'belum')" :title="(c?.percent ?? 0) + '%'"></span>
                    {{ c?.percent ?? 0 }}%
                  </td>
                  <td><strong>{{ r.percent }}%</strong></td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <section class="card" v-if="hardest.length">
          <h2>Soal tersulit (untuk ditegaskan saat workshop)</h2>
          <table class="table">
            <thead><tr><th>Modul</th><th>Soal</th><th>Jawaban salah</th><th>n</th></tr></thead>
            <tbody>
              <tr v-for="h in hardest" :key="h.key">
                <td>{{ h.module_code.toUpperCase() }}</td>
                <td><code>{{ h.question_id }}</code></td>
                <td><strong :class="{ bad: h.wrongPct >= 50 }">{{ h.wrongPct }}%</strong></td>
                <td>{{ h.n }}</td>
              </tr>
            </tbody>
          </table>
        </section>
      </template>
    </template>
  </div>
</template>

<style scoped>
.dash { display: flex; flex-direction: column; gap: 18px; }
h1, h2 { margin-top: 0; }
.muted { color: var(--ink-soft); font-size: var(--fs-small); }
.actions { display: flex; gap: 10px; flex-wrap: wrap; }
.warn-card, .error-card { border-left: 6px solid var(--upn-red); }
.mod-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 12px; }
.mod-cell { border: 1px solid var(--line); border-radius: var(--radius-sm); padding: 10px 12px; }
.mod-code { font-weight: 800; color: var(--bpjs-indigo); margin-bottom: 6px; }
.bar { height: 8px; border-radius: 999px; background: #E6E8EF; overflow: hidden; }
.fill { height: 100%; }
.fill.done { background: var(--bpjs-green); }
.mod-cell p { font-size: 12px; color: var(--ink-faint); margin: 6px 0 0; }
.scroll { overflow-x: auto; }
.table { width: 100%; border-collapse: collapse; font-size: var(--fs-small); }
.table th, .table td { text-align: left; padding: 8px 10px; border-bottom: 1px solid var(--line); }
.table th { color: var(--ink-faint); font-size: 12px; text-transform: uppercase; letter-spacing: .05em; }
.dot { display: inline-block; width: 11px; height: 11px; border-radius: 50%; margin-right: 5px; }
.st-selesai { background: var(--bpjs-green); }
.st-mulai { background: var(--upn-gold); }
.st-belum { background: #C9CEDA; }
.bad { color: var(--upn-red); }
code { background: var(--bpjs-indigo-soft); padding: 1px 6px; border-radius: 5px; font-size: 12px; }
</style>
