<script setup>
const props = defineProps({ block: { type: Object, required: true } })
</script>

<template>
  <figure class="block figure">
    <a
      v-if="block.link"
      class="fig-link"
      :href="block.link"
      target="_blank"
      rel="noopener noreferrer"
      :aria-label="'Buka sumber di tab baru: ' + (block.caption || 'gambar')"
    >
      <img :src="block.src" :alt="block.alt || block.caption || 'Ilustrasi'" loading="lazy" />
      <span class="ext-badge" aria-hidden="true">↗</span>
    </a>
    <img v-else :src="block.src" :alt="block.alt || block.caption || 'Ilustrasi'" loading="lazy" />
    <figcaption>
      <span class="caption">{{ block.caption }}</span>
      <span class="credit">
        {{ block.credit }}
        <a v-if="block.link" class="credit-link" :href="block.link" target="_blank" rel="noopener noreferrer">Buka sumber ↗</a>
      </span>
    </figcaption>
  </figure>
</template>

<style scoped>
.figure { margin: 0 0 26px; }
/* Gambar tampil pada ukuran aslinya (dibatasi area) — rasio selalu terjaga,
   tanpa kotak putih raksasa untuk figur tinggi seperti bagan Mayer. */
.figure img {
  display: block; width: auto; height: auto;
  max-width: 100%; max-height: 620px;
  margin: 0 auto;
  border: 1px solid var(--line); border-radius: var(--radius);
  background: #fff;
}
.fig-link { display: block; position: relative; }
.fig-link img { cursor: zoom-out; }
.fig-link:hover img { border-color: var(--bpjs-green); box-shadow: 0 4px 16px rgba(0, 159, 60, .15); }
.ext-badge {
  position: absolute; top: 10px; right: 12px;
  width: 26px; height: 26px; border-radius: 50%;
  background: rgba(43, 48, 120, .82); color: #fff;
  display: flex; align-items: center; justify-content: center;
  font-size: 14px; font-weight: 700;
  opacity: 0; transition: opacity .15s ease;
}
.fig-link:hover .ext-badge, .fig-link:focus-visible .ext-badge { opacity: 1; }
figcaption {
  font-size: var(--fs-small); color: var(--ink-soft);
  margin-top: 8px; line-height: 1.5;
}
.caption { display: block; }
.credit { display: block; font-size: 12.5px; color: var(--ink-faint); font-style: italic; }
.credit-link { font-style: normal; font-weight: 600; color: var(--bpjs-indigo); text-decoration: none; white-space: nowrap; }
.credit-link:hover { text-decoration: underline; }
</style>
