<template>
  <div class="card">
    <header class="card-head">
      <div>{{ $t("Headline picture") }}</div>
      <button type="button" class="delete" @click="$emit('close')" />
    </header>
    <div class="card-body">
      <img :src="image" />
    </div>
    <footer class="card-foot"></footer>
  </div>
</template>
<script lang="ts">
import { Component, Vue, Prop } from "vue-property-decorator";

@Component
export default class EventHeadline extends Vue {
  @Prop({ required: true, type: String }) image!: string;
}
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;

button.delete {
  margin-left: auto;
  @include margin-right(1rem);
}

.card {
  display: flex;
  flex-direction: column;
  max-height: calc(100vh - 40px);
  overflow: auto;
}

.card-body {
  display: flex;
  justify-content: center;
  background-color: white;
}

.card-head {
  border-bottom: 1px solid #dbdbdb;
  border-top-left-radius: 6px;
  border-top-right-radius: 6px;
  display: flex;
  padding: 20px;
  position: relative;
}

.card-foot {
  display: flex;
  padding: 20px;
  position: relative;
  border-bottom-left-radius: 6px;
  border-bottom-right-radius: 6px;
  border-top: 1px solid #dbdbdb;
}

.img {
  object-fit: contain;
}
</style>
