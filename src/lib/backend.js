// Adapter penyimpanan: Supabase (produksi) atau Local (demo/tanpa backend).
// Antarmuka yang dipakai aplikasi:
//   signIn(email, sandi)   -> participant (email + kata sandi dari admin)
//   signInGoogle()         -> participant (redirect OAuth Google)
//   restoreSession()       -> participant | null
//   signOut()
//   loadMyData()           -> { items: {}, modules: {}, quiz: [] }
//   saveItem / saveModuleProgress / saveQuizResponse
//   loadDashboard()        -> { participants, items, modules, quiz }
//   setModuleProgress(participantId, moduleCode, percent, status)  [admin]
//   resetParticipantProgress(participantId)                        [admin]
//   setPeran(email, peran)                                         [admin]

import { createClient } from '@supabase/supabase-js'
import { SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_ENABLED } from './config.js'

let sb = null
if (SUPABASE_ENABLED) {
  sb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
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
  async signIn(identifier, sandi) {
    if (!identifier || !sandi || sandi.length < 4) throw new Error('Nama pengguna/email dan kata sandi (min. 4 karakter) wajib diisi.')
    const key = identifier.includes('@') ? identifier.toLowerCase() : 'demo-' + identifier.toLowerCase()
    const nama = identifier.split('@')[0].replace(/[._-]+/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
    const participant = {
      id: 'demo-' + key,
      nama,
      email: key.includes('@') ? key : key + '@demo.local',
      kelompok: 'Demo',
      peran: key.startsWith('admin') || identifier.toLowerCase().startsWith('admin') ? 'admin' : identifier.toLowerCase().startsWith('fasilitator') ? 'fasilitator' : 'peserta'
    }
    localWrite(LS.session, participant)
    return participant
  },
  async signInGoogle() {
    throw new Error('Login Google hanya tersedia pada versi daring (Supabase).')
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
  },
  async setModuleProgress() { /* demo: tidak tersedia */ },
  async resetParticipantProgress() { /* demo: tidak tersedia */ },
  async setPeran() { /* demo: tidak tersedia */ }
}

/* ---------------- Mode Supabase ---------------- */

const supabaseBackend = {
  mode: 'supabase',

  async signIn(identifier, sandi) {
    // Identifier dapat berupa email ATAU nama pengguna (diterjemahkan ke email).
    let email = identifier.trim()
    if (!email.includes('@')) {
      const { data: resolved, error: rpcErr } = await sb.rpc('lookup_login_email', { p_username: email })
      if (rpcErr) throw new Error('Gagal memeriksa nama pengguna: ' + rpcErr.message)
      const list = Array.isArray(resolved) ? resolved : (resolved ? [resolved] : [])
      if (!list.length || !list[0]) {
        throw new Error('Nama pengguna tidak ditemukan. Gunakan nama pengguna dari administrasi atau login Google.')
      }
      email = String(list[0]).trim()
    }
    const { error } = await sb.auth.signInWithPassword({ email, password: sandi })
    if (error) throw new Error(this._authErr(error))
    return this.restoreSession()
  },

  async signInGoogle() {
    const { error } = await sb.auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo: window.location.origin + window.location.pathname }
    })
    if (error) throw new Error(this._authErr(error))
    // Peramban dialihkan ke Google; sesi dibaca ulang setelah kembali.
  },

  _authErr(error) {
    const m = (error?.message || '').toLowerCase()
    if (m.includes('invalid login credentials')) return 'Email atau kata sandi salah. Akun dibuat oleh administrasi kegiatan.'
    if (m.includes('email not confirmed')) return 'Email belum dikonfirmasi. Hubungi administrasi kegiatan.'
    if (m.includes('provider is not enabled') || m.includes('unsupported provider')) return 'Login Google belum diaktifkan di Supabase — gunakan email & kata sandi.'
    return error?.message || 'Login gagal.'
  },

  async restoreSession() {
    const { data: { session } } = await sb.auth.getSession()
    if (!session) return null
    const { data, error } = await sb.rpc('bind_and_get_me')
    if (error || !data || (Array.isArray(data) ? data.length : 0) === 0) {
      // Tidak bisa memastikan profil — perlakukan sebagai belum login.
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
      sb.from('participants').select('id,nama,email,username,kelompok,peran').order('kelompok').order('nama'),
      sb.from('module_progress').select('*'),
      sb.from('item_progress').select('*'),
      sb.from('quiz_responses').select('*')
    ])
    if (p.error) throw new Error('Dashboard hanya untuk admin/fasilitator/narasumber: ' + p.error.message)
    return {
      participants: p.data || [], modules: m.data || [],
      items: it.data || [], quiz: q.data || []
    }
  },

  async setUsername(participantId, username) {
    const { error } = await sb.rpc('admin_set_username', { p_participant_id: participantId, p_username: username })
    if (error) throw new Error(error.message)
  },

  async setModuleProgress(participantId, moduleCode, percent, status) {
    const { error } = await sb.rpc('admin_set_module_progress', {
      p_participant_id: participantId, p_module_code: moduleCode, p_percent: percent, p_status: status
    })
    if (error) throw new Error(error.message)
  },

  async resetParticipantProgress(participantId) {
    const { error } = await sb.rpc('admin_reset_all_progress', { p_participant_id: participantId })
    if (error) throw new Error(error.message)
  },

  async setPeran(email, peran) {
    const { error } = await sb.rpc('admin_set_peran', { p_email: email, p_peran: peran })
    if (error) throw new Error(error.message)
  },

  async _meId() {
    const me = await this.restoreSession()
    if (!me) throw new Error('Sesi berakhir — silakan login ulang.')
    return me.id
  }
}

export const backend = SUPABASE_ENABLED ? supabaseBackend : localBackend
export { sb as supabaseClient }
