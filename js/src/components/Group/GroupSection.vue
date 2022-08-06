<template>
  <section>
    <div class="group-section-title" :class="{ privateSection }">
      <div class="is-flex is-justify-content-center is-align-items-center">
        <b-icon :icon="icon" />
        <h2>{{ title }}</h2>
      </div>
      <router-link :to="route">{{ $t("View all") }}</router-link>
    </div>
    <div class="main-slot">
      <slot></slot>
    </div>
    <div class="create-slot">
      <slot name="create"></slot>
    </div>
  </section>
</template>

<script lang="ts">
import { Component, Vue, Prop } from "vue-property-decorator";
import { Route } from "vue-router";

@Component
export default class GroupSection extends Vue {
  @Prop({ required: true, type: String }) title!: string;

  @Prop({ required: true, type: String }) icon!: string;

  @Prop({ required: false, type: Boolean, default: true })
  privateSection!: boolean;

  @Prop({ required: true, type: Object }) route!: Route;
}
</script>
<style lang="scss" scoped>
@use "@/styles/_mixins" as *;

section {
  display: flex;
  flex-direction: column;
  margin-bottom: 2rem;
  border: 2px solid $primary;
  border-top-left-radius: 8px;
  border-top-right-radius: 8px;
  min-height: 30vh;

  .create-slot {
    display: flex;
    justify-content: flex-end;
    padding-bottom: 0.5rem;
    @include padding-right(0.5rem);
  }

  .main-slot {
    min-height: 5rem;
    padding: 2px 5px;
    flex: 1;
  }
}

div.group-section-title {
  display: flex;
  align-items: center;
  justify-content: space-between;
  color: $background-color;
  background: $primary;
  padding: 4px 16px;

  &.privateSection {
    color: $background-color;
    background: $primary;
  }

  ::v-deep & > a {
    align-self: center;
    //@include margin-right(16px);
    color: $background-color;
  }

  span {
    margin-right: 16px;
  }

  h2 {
    font-family: "Ubuntu", "Liberation Sans", "Helvetica Neue", Roboto,
      Helvetica, Arial, sans-serif;
    font-weight: 500;
    font-size: 30px;
    flex: 1;

    ::v-deep span.icon {
      flex: 0;
      height: 100%;
    }
  }
}
</style>
