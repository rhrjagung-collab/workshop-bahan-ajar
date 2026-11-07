<script setup>
const props = defineProps({ block: { type: Object, required: true } })
</script>

<template>
  <figure class="block figure">
    <img :src="block.src" :alt="block.alt || block.caption || 'Ilustrasi'" loading="lazy" />
    <figcaption>
      <span class="caption">{{ block.caption }}</span>
      <span v-if="block.credit" class="credit">Sumber: {{ block.credit }}</span>
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
figcaption {
  font-size: var(--fs-small); color: var(--ink-soft);
  margin-top: 8px; line-height: 1.5;
}
.caption { display: block; }
.credit { display: block; font-size: 12.5px; color: var(--ink-faint); font-style: italic; }
</style>
