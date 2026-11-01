// Store global: sesi, progres, dan status penyelesaian modul.

import { reactive, computed } from 'vue'
import { backend } from './backend.js'
import { modules, requiredBlocks, isBlockDone } from './course.js'

export const store = reactive({
  ready: false,
  session: null,
  items: {},        // "c1|lk1" -> {done, ...state}
  modules: {},      // "c1" -> {percent, status}
  quiz: [],         // riwayat respons kuis
  saving: 0         // penghitung indikator "Tersimpan"
})

export async function initStore() {
  store.session = await backend.restoreSession()
  if (store.session) await loadMyData()
  store.ready = true
}

export async function loadMyData() {
  const data = await backend.loadMyData()
  store.items = data.items || {}
  store.modules = data.modules || {}
  store.quiz = data.quiz || []
}

export async function login(email, kode) {
  const p = await backend.signIn(email, kode)
  store.session = p
  await loadMyData()
  return p
}

export async function logout() {
  await backend.signOut()
  store.session = null
  store.items = {}
  store.modules = {}
  store.quiz = []
}

function itemKey(moduleCode, key) { return `${moduleCode}|${key}` }

export async function saveItemState(moduleCode, key, state) {
  const k = itemKey(moduleCode, key)
  store.items[k] = { ...(store.items[k] || {}), ...state }
  store.saving++
  await backend.saveItem(moduleCode, key, store.items[k])
  store.saving = Math.max(0, store.saving - 1)
  await syncModuleProgress(moduleCode)
}

export function getItemState(moduleCode, key) {
  return store.items[itemKey(moduleCode, key)] || null
}

export async function recordQuizResponse(row) {
  store.quiz.push({ ...row, created_at: new Date().toISOString() })
  store.saving++
  await backend.saveQuizResponse(row)
  store.saving = Math.max(0, store.saving - 1)
}

// Hitung progres modul dari blok wajib, simpan bila berubah.
export async function syncModuleProgress(moduleCode) {
  const mod = modules.find(m => m.code === moduleCode)
  if (!mod) return
  const req = requiredBlocks(mod)
  const done = req.filter(b => isBlockDone(getItemState(moduleCode, b.item_key)))
  const percent = req.length ? Math.round((done.length / req.length) * 100) : 0
  const status = percent === 100 ? 'selesai' : percent > 0 ? 'mulai' : 'belum'
  const prev = store.modules[moduleCode]
  store.modules[moduleCode] = { percent, status }
  if (!prev || prev.percent !== percent || prev.status !== status) {
    await backend.saveModuleProgress(moduleCode, percent, status)
  }
}

export const isFacilitator = computed(() =>
  store.session && ['fasilitator', 'narasumber', 'admin'].includes(store.session.peran)
)

export const overallPercent = computed(() => {
  const vals = modules.map(m => store.modules[m.code]?.percent || 0)
  return Math.round(vals.reduce((a, b) => a + b, 0) / (modules.length || 1))
})

export const allModulesDone = computed(() =>
  modules.every(m => store.modules[m.code]?.status === 'selesai')
)
