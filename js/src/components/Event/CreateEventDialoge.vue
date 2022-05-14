<template>
  <div class="modal-card">
    <header class="modal-card-head">
      <p class="modal-card-title">{{ $t("General information") }}</p>
    </header>
    <section class="modal-card-body">
      <p style="color: red">
        If you want to build an audience on mobilize.berlin, we strongly advice
        you to <span v-if="!hasGroups">create a group and</span> publish your
        events on behalf of that group.
      </p>
      <p style="color: black">
        <br />As of mobilizon version 2.0, mobilizon users are able to follow
        your group (but not your user account!). For any question or assistance
        you can contact
        <a href="mailto:admin@mobilize.berlin">admin@mobilize.berlin</a>.
      </p>
      <p style="color: black">
        <br />For more information see
        <a href="https://docs.mobilize.berlin/organizer.html" target="_blank"
          >docs.mobilize.berlin/organizer.html</a
        >.
      </p>
    </section>
    <div style="background-color: white; color: black">
      <p class="modal-card-body" style="color: black; font-size: large">
        <b>{{ $t("Pick a profile or a group") }}</b>
      </p>
      <b-field>
        <organizer-picker-wrapper
          v-model="organizerActor"
          :groupsOnly="groupsOnly"
        />
      </b-field>
    </div>
    <footer class="modal-card-foot">
      <div style="display: flex; justify-content: space-between; width: 100%">
        <b-button
          type="is-primary"
          tag="router-link"
          :to="{
            name: RouteName.CREATE_EVENT,
            query: { actorId: organizerActor.id },
          }"
          exact
          v-on:click.native="$emit('close')"
        >
          {{ $t("Create") }}
        </b-button>
        <b-button
          v-if="!hasGroups"
          type="is-primary"
          tag="router-link"
          :to="{ name: RouteName.CREATE_GROUP }"
          exact
          v-on:click.native="$emit('close')"
        >
          {{ $t("Create group") }}
        </b-button>
        <div style="color: black" v-else>
          <b-switch v-model="groupsOnly"> Show groups only </b-switch>
        </div>
      </div>
    </footer>
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { LOGGED_USER_MEMBERSHIPS } from "@/graphql/actor";
import { Paginate } from "@/types/paginate";
import { IMember } from "@/types/actor/member.model";
import { ActorType, MemberRole } from "@/types/enums";
import RouteName from "../../router/name";
import OrganizerPickerWrapper from "./OrganizerPickerWrapper.vue";
import { IActor, IGroup, IPerson } from "../../types/actor";
import { CURRENT_ACTOR_CLIENT } from "../../graphql/actor";

@Component({
  components: { OrganizerPickerWrapper },
  apollo: {
    groupMemberships: {
      query: LOGGED_USER_MEMBERSHIPS,
      update: (data) => data.loggedUser.memberships,
    },
    currentActor: CURRENT_ACTOR_CLIENT,
  },
})
export default class CreateEventDialoge extends Vue {
  @Prop({ type: Object, required: false }) orgActor!: IActor;

  @Prop({ required: false }) isSwitch!: boolean;
  groupMemberships: Paginate<IMember> = { elements: [], total: 0 };
  isComponentModalActive = false;

  RouteName = RouteName;

  currentActor!: IPerson;

  get hasGroups(): boolean {
    return (
      this.groupMemberships.elements.filter((membership: IMember) =>
        [
          MemberRole.ADMINISTRATOR,
          MemberRole.MODERATOR,
          MemberRole.CREATOR,
        ].includes(membership.role)
      ).length > 0
    );
  }

  get actualMemberships(): IMember[] {
    return this.groupMemberships.elements.filter((membership: IMember) =>
      [
        MemberRole.ADMINISTRATOR,
        MemberRole.MODERATOR,
        MemberRole.CREATOR,
      ].includes(membership.role)
    );
  }
  get firstGroup(): IGroup {
    return this.actualMemberships.map((member) => member.parent)[0];
  }

  get groupsOnly(): boolean {
    if (this.isSwitch !== undefined) {
      return this.isSwitch;
    }
    return this.hasGroups;
  }

  set groupsOnly(toggle: boolean) {
    this.isSwitch = toggle;
  }

  get organizerActor(): IActor {
    if (this.orgActor) {
      return this.orgActor;
    }
    if (this.hasGroups && this.groupsOnly) {
      return this.firstGroup;
    }
    return this.currentActor;
  }

  set organizerActor(organizerActor: IActor) {
    if (organizerActor?.type === ActorType.GROUP) {
      this.orgActor = organizerActor as IGroup;
    } else {
      this.orgActor = organizerActor;
    }
  }
}
</script>
