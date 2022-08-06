<template>
  <li :class="{ active: sectionActive }">
    <router-link v-if="to" :to="to">{{ title }}</router-link>
    <b v-else>{{ title }}</b>
    <ul>
      <slot></slot>
    </ul>
  </li>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import SettingMenuItem from "@/components/Settings/SettingMenuItem.vue";
import { Route } from "vue-router";

@Component({
  components: { SettingMenuItem },
})
export default class SettingMenuSection extends Vue {
  @Prop({ required: false, type: String }) title!: string;

  @Prop({ required: true, type: Object }) to!: Route;

  get sectionActive(): boolean {
    if (this.$slots.default) {
      return this.$slots.default.some(
        ({
          componentOptions: {
            // eslint-disable-next-line @typescript-eslint/ban-ts-comment
            // @ts-ignore
            propsData: { to },
          },
        }) => to && to.name === this.$route.name
      );
    }
    return false;
  }
}
</script>

<style lang="scss" scoped>
ul {
  filter: drop-shadow(0px 2px 6px rgba($black, 0.2));
}

li {
  font-size: 1.3rem;

  a,
  b {
    border-top-left-radius: 8px;
    border-top-right-radius: 8px;
    background-color: $primary;
    color: $background-color;
    cursor: pointer;
    display: block;
    padding: 10px 16px;
    font-weight: 500;
  }
}
</style>
