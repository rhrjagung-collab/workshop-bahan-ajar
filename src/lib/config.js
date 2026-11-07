// Konfigurasi runtime.
// URL proyek dan kunci publishable Supabase bersifat publik (dikirim ke peramban
// peserta saat runtime), sehingga dipakai sebagai nilai bawaan — tetap dapat
// ditimpa lewat env var VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY di Vercel.
// Kunci secret/service_role TIDAK PERNAH berada di kode klien.

const url = import.meta.env.VITE_SUPABASE_URL || 'https://oltafrxhkzojbdowcydc.supabase.co'
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || 'sb_publishable_iv2KUICUAVqpWZM3FlNLsg_gUvnpGFV'

export const SUPABASE_URL = url
export const SUPABASE_ANON_KEY = anonKey
export const SUPABASE_ENABLED = Boolean(url && anonKey)
export const DEMO_MODE = !SUPABASE_ENABLED
