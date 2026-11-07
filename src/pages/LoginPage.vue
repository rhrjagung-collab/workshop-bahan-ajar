<script setup>
// Login: Google (Gmail) ATAU email + kata sandi yang dibuat administrasi.
// Ketersediaan login Google dibaca dari /auth/v1/settings — bila provider
// belum diaktifkan di proyek Supabase, tombolnya disembunyikan otomatis.
import { ref, onMounted } from 'vue'
import { login, loginGoogle } from '../lib/store.js'
import { go } from '../lib/router.js'
import { DEMO_MODE, SUPABASE_URL, SUPABASE_ANON_KEY } from '../lib/config.js'

const email = ref('')
const sandi = ref('')
const err = ref('')
const busy = ref(false)
const gBusy = ref(false)
const googleEnabled = ref(DEMO_MODE ? false : null)

onMounted(async () => {
  if (DEMO_MODE) return
  try {
    const r = await fetch(`${SUPABASE_URL}/auth/v1/settings`, {
      headers: { apikey: SUPABASE_ANON_KEY }
    })
    const s = await r.json()
    googleEnabled.value = Boolean(s?.external?.google)
  } catch {
    googleEnabled.value = false
  }
})

async function submit() {
  err.value = ''
  busy.value = true
  try {
    await login(email.value, sandi.value)
    go('/')
  } catch (e) {
    err.value = e.message || 'Login gagal.'
  } finally {
    busy.value = false
  }
}

async function google() {
  err.value = ''
  gBusy.value = true
  try {
    await loginGoogle()
    // OAuth mengalihkan peramban; bila gagal (provider belum aktif) pesan muncul di sini.
  } catch (e) {
    err.value = e.message || 'Login Google gagal.'
    gBusy.value = false
  }
}
</script>

<template>
  <div class="login-wrap">
    <div class="card login-card">
      <h1>Masuk</h1>
      <p class="muted">
        Gunakan akun Gmail Anda atau email + kata sandi yang dibuat oleh administrasi kegiatan
        (Sri Gunda Fahriana Fahruddin). Tidak ada pendaftaran mandiri.
      </p>

      <button v-if="googleEnabled === true" class="btn btn-google" type="button" :disabled="gBusy" @click="google">
        <svg width="18" height="18" viewBox="0 0 48 48" aria-hidden="true">
          <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
          <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
          <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
          <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
        </svg>
        {{ gBusy ? 'Mengalihkan ke Google…' : 'Masuk dengan akun Google' }}
      </button>
      <p v-else-if="googleEnabled === false" class="g-off">
        Login Google belum diaktifkan pada proyek Supabase — gunakan email &amp; kata sandi di bawah.
      </p>

      <div class="divider"><span>atau</span></div>

      <form @submit.prevent="submit">
        <div class="field">
          <label for="email">Email</label>
          <input id="email" v-model="email" type="email" required placeholder="nama@perusahaan" autocomplete="email" />
        </div>
        <div class="field">
          <label for="sandi">Kata sandi</label>
          <input id="sandi" v-model="sandi" type="password" required placeholder="Dibuat oleh administrasi" autocomplete="current-password" />
        </div>
        <p v-if="err" class="error" role="alert">{{ err }}</p>
        <button class="btn btn-primary" type="submit" :disabled="busy">
          {{ busy ? 'Memproses…' : 'Masuk' }}
        </button>
      </form>
      <p v-if="DEMO_MODE" class="demo">
        Mode demo lokal: email apa pun + sandi ≥ 4 karakter. Email berawalan
        <code>admin</code> melihat kontrol admin, berawalan <code>fasilitator</code> melihat dashboard.
      </p>
    </div>
  </div>
</template>

<style scoped>
.login-wrap { display: flex; justify-content: center; padding: 30px 0; }
.login-card { width: 100%; max-width: 460px; }
h1 { margin-top: 0; }
.muted { color: var(--ink-soft); font-size: var(--fs-small); }
.field { margin: 14px 0; }
.btn-google {
  width: 100%; justify-content: center; gap: 10px;
  background: #fff; color: var(--ink);
  border: 1.5px solid var(--line); border-radius: var(--radius-sm);
  padding: 11px 16px; font-weight: 600; font-size: var(--fs-small);
  cursor: pointer;
}
.btn-google:hover { border-color: var(--bpjs-indigo); }
.g-off {
  background: var(--bpjs-indigo-soft); color: var(--bpjs-indigo-dark);
  padding: 10px 12px; border-radius: var(--radius-sm); font-size: var(--fs-small);
  text-align: center; margin: 0;
}
.divider {
  display: flex; align-items: center; gap: 12px;
  margin: 18px 0 6px; color: var(--ink-faint); font-size: 12.5px;
}
.divider::before, .divider::after { content: ''; flex: 1; height: 1px; background: var(--line); }
.error {
  background: var(--upn-red-soft); color: var(--upn-red);
  padding: 10px 12px; border-radius: var(--radius-sm); font-size: var(--fs-small);
}
.demo {
  margin-top: 16px; font-size: 13px; color: var(--upn-gold-dark);
  background: var(--upn-gold-soft); padding: 10px 12px; border-radius: var(--radius-sm);
}
code { background: rgba(0,0,0,.06); padding: 1px 5px; border-radius: 4px; }
</style>
