<script setup>
// Dashboard: admin/fasilitator/narasumber memantau kelengkapan peserta.
// Admin tambahan: membuka (tandai selesai) / mengulang progres peserta
// dan mengubah peran — dieksekusi lewat RPC SECURITY DEFINER di Supabase.
import { ref, computed, reactive, onMounted } from 'vue'
import { backend } from '../lib/backend.js'
import { modules } from '../lib/course.js'
import { isFacilitator, store, adminActions } from '../lib/store.js'
import { go } from '../lib/router.js'
import { DEMO_MODE } from '../lib/config.js'

const data = ref(null)
const err = ref('')
const loading = ref(true)
const adminMsg = ref('')
const adminBusy = ref(false)
const sel = reactive({})        // participantId -> module code terpilih
const peranSel = reactive({})   // participantId -> peran terpilih
const nu = reactive({ nama: '', email: '', username: '', sandi: '', kelompok: '' })

if (!store.session) go('/login')

async function refresh() {
  loading.value = true
  err.value = ''
  try {
    data.value = await backend.loadDashboard()
    for (const p of (data.value?.participants || [])) {
      if (!sel[p.id]) sel[p.id] = 'c0'
      if (!peranSel[p.id]) peranSel[p.id] = p.peran
    }
  } catch (e) {
    err.value = e.message
  } finally {
    loading.value = false
  }
}

onMounted(refresh)

const isAdmin = computed(() => store.session?.peran === 'admin')

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

function downloadCsv(name, rowsOut) {
  const csv = rowsOut.map(r => r.map(c => `"${String(c ?? '').replaceAll('"', '""')}"`).join(';')).join('\n')
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

/* ---------- Aksi admin ---------- */

async function adminRun(fn, okMsg) {
  if (DEMO_MODE) { adminMsg.value = 'Aksi admin hanya tersedia pada versi daring (Supabase).' ; return }
  adminBusy.value = true
  adminMsg.value = ''
  try {
    await fn()
    adminMsg.value = okMsg
    await refresh()
  } catch (e) {
    adminMsg.value = 'Gagal: ' + (e.message || 'kesalahan tidak diketahui')
  } finally {
    adminBusy.value = false
  }
}

function unlockModule(p) {
  const code = sel[p.id]
  adminRun(
    () => adminActions.setModuleProgress(p.id, code, 100, 'selesai'),
    `Modul ${code.toUpperCase()} atas nama ${p.nama} ditandai selesai (terbuka).`
  )
}

function resetModule(p) {
  const code = sel[p.id]
  adminRun(
    () => adminActions.setModuleProgress(p.id, code, 0, 'belum'),
    `Progres ${code.toUpperCase()} atas nama ${p.nama} dikembalikan ke awal.`
  )
}

function resetAll(p) {
  if (!confirm(`Reset SELURUH progres ${p.nama}? Tindakan ini tidak dapat dibatalkan.`)) return
  adminRun(
    () => adminActions.resetParticipantProgress(p.id),
    `Seluruh progres ${p.nama} telah direset.`
  )
}

function applyPeran(p) {
  adminRun(
    () => adminActions.setPeran(p.email, peranSel[p.id]),
    `Peran ${p.nama} diubah menjadi ${peranSel[p.id]}.`
  )
}

function setUsername(p, value) {
  if (!value || value.trim() === (p.username || '')) return
  adminRun(
    () => adminActions.setUsername(p.id, value),
    `Nama pengguna ${p.nama} disimpan — dapat dipakai untuk login.`
  )
}

async function createUser() {
  if (DEMO_MODE) { adminMsg.value = 'Penambahan peserta hanya tersedia pada versi daring (Supabase).'; return }
  adminBusy.value = true
  adminMsg.value = ''
  try {
    const msg = await adminActions.createUser(nu.nama, nu.email, nu.sandi, nu.username, nu.kelompok)
    adminMsg.value = msg
    nu.nama = ''; nu.email = ''; nu.sandi = ''; nu.username = ''; nu.kelompok = ''
    await refresh()
  } catch (e) {
    adminMsg.value = 'Gagal: ' + (e.message || 'kesalahan tidak diketahui')
  } finally {
    adminBusy.value = false
  }
}
</script>

<template>
  <div class="dash">
    <div v-if="!isFacilitator && !loading" class="card warn-card">
      <h1>Akses terbatas</h1>
      <p>Dashboard hanya untuk admin, fasilitator, dan narasumber. Peran Anda saat ini: <strong>{{ store.session?.peran }}</strong>.</p>
      <a class="btn btn-ghost" href="#/">Kembali</a>
    </div>

    <template v-else>
      <div class="card head-card">
        <h1>Dashboard {{ isAdmin ? 'admin' : 'fasilitator' }}</h1>
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

        <section v-if="isAdmin" class="card admin-card">
          <h2>Tambah peserta baru</h2>
          <p class="muted">Membuat akun login lengkap (email + kata sandi + baris roster) sekaligus. Kata sandi minimal 6 karakter.</p>
          <form class="add-form" @submit.prevent="createUser">
            <div class="form-row">
              <div class="form-field"><label>Nama lengkap</label><input v-model="nu.nama" type="text" required placeholder="mis. Agung Raharjo" /></div>
              <div class="form-field"><label>Email</label><input v-model="nu.email" type="email" required placeholder="mis. agung@bpjs.co.id" /></div>
            </div>
            <div class="form-row">
              <div class="form-field"><label>Nama pengguna (opsional)</label><input v-model="nu.username" type="text" placeholder="mis. agung.raharjo" /></div>
              <div class="form-field"><label>Kata sandi</label><input v-model="nu.sandi" type="text" required minlength="6" placeholder="min. 6 karakter" /></div>
              <div class="form-field"><label>Kelompok</label><input v-model="nu.kelompok" type="text" placeholder="mis. Kelompok 1" /></div>
            </div>
            <button class="btn btn-green" type="submit" :disabled="adminBusy">Buat akun peserta</button>
          </form>
        </section>

        <section v-if="isAdmin" class="card admin-card">
          <h2>Kontrol admin — kelola peserta</h2>
          <p class="muted">
            Atur nama pengguna untuk login, membuka modul (tandai selesai) bagi peserta yang
            terkendala, mengulang progres, dan mengatur peran. Perubahan langsung berpengaruh.
          </p>
          <p v-if="adminMsg" class="admin-msg" role="status">{{ adminMsg }}</p>
          <div class="scroll">
            <table class="table">
              <thead>
                <tr>
                  <th>Peserta</th><th>Nama pengguna (login)</th><th>Peran</th>
                  <th>Buka kunci / ulang modul</th><th>Aksi lain</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="r in rows" :key="r.p.id">
                  <td><strong>{{ r.p.nama }}</strong><br /><span class="muted">{{ r.p.email }}</span></td>
                  <td>
                    <input
                      class="sel" type="text" style="max-width:160px"
                      :value="r.p.username || ''"
                      :placeholder="'belum ada'"
                      :disabled="adminBusy || r.p.id === store.session.id"
                      @change="setUsername(r.p, $event.target.value)"
                    />
                  </td>
                  <td>
                    <select v-model="peranSel[r.p.id]" class="sel" :disabled="adminBusy || r.p.id === store.session.id">
                      <option value="peserta">peserta</option>
                      <option value="fasilitator">fasilitator</option>
                      <option value="narasumber">narasumber</option>
                      <option value="admin">admin</option>
                    </select>
                    <button class="btn btn-ghost btn-small" :disabled="adminBusy || r.p.id === store.session.id" @click="applyPeran(r.p)">Terapkan</button>
                  </td>
                  <td>
                    <select v-model="sel[r.p.id]" class="sel" :disabled="adminBusy">
                      <option v-for="m in modules" :key="m.code" :value="m.code">{{ m.code.toUpperCase() }} — {{ m.judul }}</option>
                    </select>
                    <button class="btn btn-green btn-small" :disabled="adminBusy" @click="unlockModule(r.p)">Tandai selesai</button>
                    <button class="btn btn-ghost btn-small" :disabled="adminBusy" @click="resetModule(r.p)">Ulang modul</button>
                  </td>
                  <td>
                    <button class="btn btn-danger btn-small" :disabled="adminBusy" @click="resetAll(r.p)">Reset semua progres</button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <p v-if="DEMO_MODE" class="hint">Mode demo: kontrol admin aktif hanya pada versi daring dengan Supabase.</p>
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
.admin-card { border-left: 6px solid var(--upn-gold); }
.admin-msg {
  background: var(--bpjs-green-soft); color: var(--bpjs-green-dark);
  padding: 10px 12px; border-radius: var(--radius-sm); font-size: var(--fs-small);
}
.mod-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 12px; }
.mod-cell { border: 1px solid var(--line); border-radius: var(--radius-sm); padding: 10px 12px; }
.mod-code { font-weight: 800; color: var(--bpjs-indigo); margin-bottom: 6px; }
.bar { height: 8px; border-radius: 999px; background: #E6E8EF; overflow: hidden; }
.fill { height: 100%; }
.fill.done { background: var(--bpjs-green); }
.mod-cell p { font-size: 12px; color: var(--ink-faint); margin: 6px 0 0; }
.scroll { overflow-x: auto; }
.table { width: 100%; border-collapse: collapse; font-size: var(--fs-small); }
.table th, .table td { text-align: left; padding: 8px 10px; border-bottom: 1px solid var(--line); vertical-align: middle; }
.table th { color: var(--ink-faint); font-size: 12px; text-transform: uppercase; letter-spacing: .05em; }
.dot { display: inline-block; width: 11px; height: 11px; border-radius: 50%; margin-right: 5px; }
.st-selesai { background: var(--bpjs-green); }
.st-mulai { background: var(--upn-gold); }
.st-belum { background: #C9CEDA; }
.bad { color: var(--upn-red); }
code { background: var(--bpjs-indigo-soft); padding: 1px 6px; border-radius: 5px; font-size: 12px; }
.sel { max-width: 200px; font-size: var(--fs-small); padding: 7px 8px; margin-bottom: 4px; }
.add-form { display: flex; flex-direction: column; gap: 12px; margin-top: 8px; }
.form-row { display: flex; gap: 12px; flex-wrap: wrap; }
.form-field { flex: 1; min-width: 180px; text-align: left; }
.btn-danger { background: var(--upn-red); color: #fff; }
.btn-danger:hover { filter: brightness(1.1); }
td .btn { margin: 2px 4px 2px 0; }
</style>
