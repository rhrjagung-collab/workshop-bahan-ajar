// Konfigurasi runtime.
// Mode Supabase aktif bila kedua env var tersedia; selain itu aplikasi berjalan
// dalam mode demo lokal (progres tersimpan di localStorage peramban).

const url = import.meta.env.VITE_SUPABASE_URL || ''
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || ''

export const SUPABASE_URL = url
export const SUPABASE_ANON_KEY = anonKey
export const SUPABASE_ENABLED = Boolean(url && anonKey)
export const DEMO_MODE = !SUPABASE_ENABLED
