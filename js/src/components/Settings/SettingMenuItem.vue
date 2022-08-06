<template>
  <li class="setting-menu-item" :class="{ active: isActive }">
    <router-link v-if="to" :to="to">
      <span>{{ title }}</span>
    </router-link>
    <span v-else>{{ title }}</span>
  </li>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { Route } from "vue-router";

@Component
export default class SettingMenuItem extends Vue {
  @Prop({ required: false, type: String }) title!: string;

  @Prop({ required: true, type: Object }) to!: Route;

  get isActive(): boolean {
    if (!this.to) return false;
    if (this.to.name === this.$route.name) {
      if (this.to.params) {
        return this.to.params.identityName === this.$route.params.identityName;
      }
      return true;
    }
    return false;
  }
}
</script>

<style lang="scss" scoped>
li.setting-menu-item {
  font-size: 1.05rem;
  background-color: $background-color;
  color: $primary;
  padding: 12px 16px;

  span {
    display: block;
  }

  a {
    display: block;
    color: inherit;
  }

  &:hover,
  &.active {
    cursor: pointer;
    color: $danger;
  }

  &:hover {
    background-color: $white;
    color: $tertiary;
  }
}

.setting-menu-item:last-child {
  border-bottom-right-radius: 8px;
  border-bottom-left-radius: 8px;
  margin-bottom: 16px;
}
</style>
