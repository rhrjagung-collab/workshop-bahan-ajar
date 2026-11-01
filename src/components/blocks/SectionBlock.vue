<script setup>
// Judul seksi bergaya deck: kalimat tindakan bernomor — membawa ritme
// deck akademik (academic-html-deck) ke dalam halaman modul.
const props = defineProps({ block: { type: Object, required: true } })
</script>

<template>
  <section class="block section-head">
    <span v-if="block.num" class="num">{{ block.num }}</span>
    <h2>{{ block.title }}</h2>
    <p v-if="block.sub" class="sub">{{ block.sub }}</p>
  </section>
</template>

<style scoped>
.section-head {
  margin: 34px 0 16px;
  padding-top: 6px;
  border-top: 3px solid var(--upn-gold);
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  gap: 12px;
}
.section-head:first-child { margin-top: 8px; }
.num {
  flex: none;
  width: 34px; height: 34px; border-radius: 10px;
  background: var(--bpjs-indigo); color: #fff;
  display: inline-flex; align-items: center; justify-content: center;
  font-weight: 800; font-size: 16px;
}
h2 {
  margin: 0; font-size: clamp(19px, 2.6vw, 25px);
  color: var(--bpjs-indigo-dark); line-height: 1.3;
  max-width: 60ch;
}
.sub { width: 100%; margin: 2px 0 0; color: var(--ink-soft); font-size: var(--fs-small); }
</style>
