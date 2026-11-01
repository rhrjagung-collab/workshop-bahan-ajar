// Router hash sederhana (#/ , #/modul/c1 , dst.) — tanpa dependensi,
// bekerja di Vercel maupun hosting statis mana pun tanpa konfigurasi rewrite.

import { reactive } from 'vue'

function parse() {
  const h = location.hash.replace(/^#/, '') || '/'
  const [path] = h.split('?')
  return path || '/'
}

export const route = reactive({ path: parse() })

window.addEventListener('hashchange', () => {
  route.path = parse()
  window.scrollTo({ top: 0, behavior: 'instant' })
})

export function go(path) {
  location.hash = '#' + path
}
