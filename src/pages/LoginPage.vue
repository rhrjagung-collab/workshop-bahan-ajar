<script setup>
// Login: Google (Gmail) ATAU nama pengguna/email + kata sandi dari administrasi.
// Ketersediaan login Google dibaca dari /auth/v1/settings — bila provider
// belum diaktifkan di proyek Supabase, tombolnya disembunyikan otomatis.
import { ref, onMounted } from 'vue'
import { login, loginGoogle } from '../lib/store.js'
import { go } from '../lib/router.js'
import { DEMO_MODE, SUPABASE_URL, SUPABASE_ANON_KEY } from '../lib/config.js'

const identifier = ref('')
const sandi = ref('')
const showSandi = ref(false)
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
    await login(identifier.value, sandi.value)
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
      <div class="login-brand" aria-hidden="true">
        <img src="../assets/bpjs-kesehatan.png" alt="" />
        <span>×</span>
        <img class="brand-upn" src="../assets/upnvj.png" alt="" />
      </div>
      <h1>Selamat datang kembali</h1>
      <p class="muted">Masuk untuk melanjutkan modul persiapan Anda.</p>

      <button v-if="googleEnabled === true" class="btn btn-google" type="button" :disabled="gBusy" @click="google">
        <svg width="18" height="18" viewBox="0 0 48 48" aria-hidden="true">
          <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
          <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
          <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
          <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
        </svg>
        {{ gBusy ? 'Mengalihkan ke Google…' : 'Lanjutkan dengan Google' }}
      </button>
      <p v-else-if="googleEnabled === false" class="g-off">
        Login dengan akun Google belum tersedia — gunakan nama pengguna di bawah.
      </p>

      <div class="divider"><span>atau</span></div>

      <form @submit.prevent="submit">
        <div class="field">
          <label for="identifier">Nama pengguna atau email</label>
          <input id="identifier" v-model="identifier" type="text" required
                 placeholder="mis. agus.raharjo" autocomplete="username" />
        </div>
        <div class="field">
          <label for="sandi">Kata sandi</label>
          <div class="pass-wrap">
            <input
              id="sandi" v-model="sandi" :type="showSandi ? 'text' : 'password'" required
              placeholder="Kata sandi Anda" autocomplete="current-password"
            />
            <button
              type="button" class="toggle-pass"
              :aria-label="showSandi ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi'"
              :title="showSandi ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi'"
              @click="showSandi = !showSandi"
            >
              <svg v-if="!showSandi" width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
              </svg>
              <svg v-else width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/>
                <line x1="1" y1="1" x2="23" y2="23"/>
              </svg>
            </button>
          </div>
        </div>
        <p v-if="err" class="error" role="alert">{{ err }}</p>
        <button class="btn btn-primary" type="submit" :disabled="busy">
          {{ busy ? 'Memproses…' : 'Masuk' }}
        </button>
      </form>
      <p class="footnote">
        Akun dibagikan oleh panitia kegiatan. Mengalami kendala akses?
        Hubungi administrasi kegiatan.
      </p>
    </div>
  </div>
</template>

<style scoped>
.login-wrap { display: flex; justify-content: center; padding: 40px 0; }
.login-card { width: 100%; max-width: 440px; text-align: center; }
.login-brand { display: flex; align-items: center; justify-content: center; gap: 10px; margin-bottom: 18px; }
.login-brand img { height: 30px; }
.login-brand .brand-upn { height: 32px; border-radius: 50%; background: #fff; }
.login-brand span { color: var(--ink-faint); font-weight: 700; }
h1 { margin: 0 0 6px; }
.muted { color: var(--ink-soft); font-size: var(--fs-small); margin: 0 0 18px; }
.field { margin: 14px 0; text-align: left; }
.pass-wrap { position: relative; }
.pass-wrap input { padding-right: 44px; }
.toggle-pass {
  position: absolute; right: 6px; top: 50%; transform: translateY(-50%);
  width: 32px; height: 32px; border: none; background: transparent;
  color: var(--ink-faint); cursor: pointer; border-radius: 6px;
  display: flex; align-items: center; justify-content: center;
}
.toggle-pass:hover { color: var(--bpjs-indigo); background: var(--bpjs-indigo-soft); }
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
  margin: 0;
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
form .btn-primary { width: 100%; justify-content: center; margin-top: 6px; }
.footnote {
  margin-top: 18px; font-size: 12.5px; color: var(--ink-faint);
  border-top: 1px solid var(--line); padding-top: 12px;
}
code { background: rgba(0,0,0,.06); padding: 1px 5px; border-radius: 4px; }
</style>
