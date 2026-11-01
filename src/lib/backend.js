// Adapter penyimpanan: Supabase (produksi) atau Local (demo/tanpa backend).
// Antarmuka yang dipakai aplikasi:
//   signIn(email, kode) -> participant
//   restoreSession()    -> participant | null
//   signOut()
//   loadMyData()        -> { items: {}, modules: {}, quiz: [] }
//   saveItem(moduleCode, itemKey, state)
//   saveModuleProgress(moduleCode, percent, status)
//   saveQuizResponse(row)
//   loadDashboard()     -> { participants, items, modules, quiz }

import { createClient } from '@supabase/supabase-js'
import { SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_ENABLED } from './config.js'

let sb = null
if (SUPABASE_ENABLED) {
  sb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: { persistSession: true, autoRefreshToken: true }
  })
}

/* ---------------- Mode lokal (demo) ---------------- */

const LS = {
  session: 'mjs.session',
  data: 'mjs.data.'
}

function localRead(key, fallback) {
  try { return JSON.parse(localStorage.getItem(key)) ?? fallback } catch { return fallback }
}
function localWrite(key, value) {
  localStorage.setItem(key, JSON.stringify(value))
}

const localBackend = {
  mode: 'local',
  async signIn(email, kode) {
    // Demo: roster contoh; kode akses bebas (min. 4 karakter).
    if (!email || !kode || kode.length < 4) throw new Error('Email dan kode akses (min. 4 karakter) wajib diisi.')
    const nama = email.split('@')[0].replace(/[._-]+/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
    const participant = {
      id: 'demo-' + email.toLowerCase(),
      nama,
      email: email.toLowerCase(),
      kelompok: 'Demo',
      peran: email.toLowerCase().endsWith('@fasilitator.id') ? 'fasilitator' : 'peserta'
    }
    localWrite(LS.session, participant)
    return participant
  },
  async restoreSession() { return localRead(LS.session, null) },
  async signOut() { localStorage.removeItem(LS.session) },
  async loadMyData() {
    const s = localRead(LS.session, null)
    if (!s) return { items: {}, modules: {}, quiz: [] }
    const d = localRead(LS.data + s.id, { items: {}, modules: {}, quiz: [] })
    return { items: d.items || {}, modules: d.modules || {}, quiz: d.quiz || [] }
  },
  async saveItem(moduleCode, itemKey, state) {
    const s = localRead(LS.session, null); if (!s) return
    const d = localRead(LS.data + s.id, { items: {}, modules: {}, quiz: [] })
    d.items[`${moduleCode}|${itemKey}`] = { ...(d.items[`${moduleCode}|${itemKey}`] || {}), ...state, updated_at: new Date().toISOString() }
    localWrite(LS.data + s.id, d)
  },
  async saveModuleProgress(moduleCode, percent, status) {
    const s = localRead(LS.session, null); if (!s) return
    const d = localRead(LS.data + s.id, { items: {}, modules: {}, quiz: [] })
    d.modules[moduleCode] = { percent, status, updated_at: new Date().toISOString() }
    localWrite(LS.data + s.id, d)
  },
  async saveQuizResponse(row) {
    const s = localRead(LS.session, null); if (!s) return
    const d = localRead(LS.data + s.id, { items: {}, modules: {}, quiz: [] })
    d.quiz.push({ ...row, created_at: new Date().toISOString() })
    localWrite(LS.data + s.id, d)
  },
  async loadDashboard() {
    return { participants: [], items: {}, modules: {}, quiz: [], empty: true }
  }
}

/* ---------------- Mode Supabase ---------------- */

const supabaseBackend = {
  mode: 'supabase',

  async signIn(email, kode) {
    // 1) sesi anonim  2) klaim baris roster via RPC SECURITY DEFINER
    const { error: anonErr } = await sb.auth.signInAnonymously()
    if (anonErr) throw new Error('Gagal memulai sesi: ' + anonErr.message)
    const { data, error } = await sb.rpc('claim_participant', { p_email: email.trim(), p_kode: kode.trim() })
    if (error) { await sb.auth.signOut(); throw new Error('Login gagal: ' + error.message) }
    if (!data || data.length === 0) {
      await sb.auth.signOut()
      throw new Error('Email atau kode akses tidak cocok dengan daftar peserta. Hubungi administrasi kegiatan.')
    }
    const p = Array.isArray(data) ? data[0] : data
    const participant = { id: p.id, nama: p.nama, email: p.email, kelompok: p.kelompok, peran: p.peran }
    return participant
  },

  async restoreSession() {
    const { data: { session } } = await sb.auth.getSession()
    if (!session) return null
    const { data, error } = await sb.rpc('get_me')
    if (error || !data || (Array.isArray(data) ? data.length : 0) === 0) {
      await sb.auth.signOut()
      return null
    }
    const p = Array.isArray(data) ? data[0] : data
    return { id: p.id, nama: p.nama, email: p.email, kelompok: p.kelompok, peran: p.peran }
  },

  async signOut() { await sb.auth.signOut() },

  async loadMyData() {
    const [{ data: items }, { data: modules }, { data: quiz }] = await Promise.all([
      sb.from('item_progress').select('*'),
      sb.from('module_progress').select('*'),
      sb.from('quiz_responses').select('*').order('created_at')
    ])
    const itemMap = {}
    for (const r of items || []) itemMap[`${r.module_code}|${r.item_key}`] = r.state || {}
    const moduleMap = {}
    for (const r of modules || []) moduleMap[r.module_code] = { percent: r.percent, status: r.status }
    return { items: itemMap, modules: moduleMap, quiz: quiz || [] }
  },

  async saveItem(moduleCode, itemKey, state) {
    const me = await this._meId()
    const { error } = await sb.from('item_progress').upsert(
      { participant_id: me, module_code: moduleCode, item_key: itemKey, state, updated_at: new Date().toISOString() },
      { onConflict: 'participant_id,module_code,item_key' }
    )
    if (error) console.warn('saveItem gagal:', error.message)
  },

  async saveModuleProgress(moduleCode, percent, status) {
    const me = await this._meId()
    const { error } = await sb.from('module_progress').upsert(
      { participant_id: me, module_code: moduleCode, percent, status, updated_at: new Date().toISOString() },
      { onConflict: 'participant_id,module_code' }
    )
    if (error) console.warn('saveModuleProgress gagal:', error.message)
  },

  async saveQuizResponse(row) {
    const me = await this._meId()
    const { error } = await sb.from('quiz_responses').insert({ ...row, participant_id: me })
    if (error) console.warn('saveQuizResponse gagal:', error.message)
  },

  async loadDashboard() {
    const [p, m, it, q] = await Promise.all([
      sb.from('participants').select('id,nama,email,kelompok,peran').order('kelompok').order('nama'),
      sb.from('module_progress').select('*'),
      sb.from('item_progress').select('*'),
      sb.from('quiz_responses').select('*')
    ])
    if (p.error) throw new Error('Dashboard hanya untuk fasilitator/narasumber: ' + p.error.message)
    return {
      participants: p.data || [], modules: m.data || [],
      items: it.data || [], quiz: q.data || []
    }
  },

  async _meId() {
    const me = await this.restoreSession()
    if (!me) throw new Error('Sesi berakhir — silakan login ulang.')
    return me.id
  }
}

export const backend = SUPABASE_ENABLED ? supabaseBackend : localBackend
export { sb as supabaseClient }
