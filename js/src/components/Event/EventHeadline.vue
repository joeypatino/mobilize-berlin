<template>
  <div class="card">
    <header class="card-head">
      <div>{{ $t("Headline picture") }}</div>
      <b-button
        inverted
        type="button is-primary"
        class="delete"
        @click="$emit('close')"
      />
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

.img {
  object-fit: contain;
}
</style>
