// Loader konten course. Modul didefinisikan sebagai JSON terpisah agar mudah
// ditinjau narasumber dan direvisi tanpa menyentuh kode.

import courseMeta from '../content/course.json'
import c0 from '../content/c0-orientasi.json'
import c1 from '../content/c1-pembelajaran-aktif.json'
import c2 from '../content/c2-tujuan-alignment.json'
import c3 from '../content/c3-alur-storyboard.json'
import c4 from '../content/c4-desain-slide.json'
import c5 from '../content/c5-visualisasi.json'
import c6 from '../content/c6-interaksi-teknologi.json'
import c7 from '../content/c7-persiapan-ujian.json'

export const course = courseMeta

const contentByCode = { c0, c1, c2, c3, c4, c5, c6, c7 }

export const modules = courseMeta.modules.map(m => {
  const content = contentByCode[m.code]
  if (!content) throw new Error(`Konten modul ${m.code} tidak ditemukan`)
  return { ...m, ...content, meta: m }
})

export function getModule(code) {
  return modules.find(m => m.code === code)
}

export function nextModule(code) {
  const i = modules.findIndex(m => m.code === code)
  return i >= 0 && i < modules.length - 1 ? modules[i + 1] : null
}

// Blok yang dihitung untuk penyelesaian modul = blok interaktif (punya item_key
// dan required !== false).
export function requiredBlocks(mod) {
  return (mod.blocks || []).filter(b => b.item_key && b.required !== false)
}

export function isBlockDone(state) {
  return Boolean(state && state.done)
}
