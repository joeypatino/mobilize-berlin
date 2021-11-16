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
    <div style="background-color: white">
      <p class="modal-card-body" style="color: black; font-size: large">
        <b>{{ $t("Pick a profile or a group") }}</b>
      </p>
      <b-field>
        <organizer-picker-wrapper v-model="organizerActor" />
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
      </div>
    </footer>
    <b-modal
      :active.sync="isComponentModalActive"
      has-modal-card
      :close-button-aria-label="$t('Close')"
    >
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title">{{ $t("Pick a profile or a group") }}</p>
        </header>
        <section class="modal-card-body">
          <div>
            <organizer-picker
              v-model="selectedActor"
              @input="relay"
              :restrict-moderator-level="true"
              :groupsOnly="true"
            />
          </div>
        </section>
        <footer class="modal-card-foot">
          <b-button
            class="button is-primary"
            type="button"
            v-on:click.native="pickActor && $emit('close')"
            tag="router-link"
            :to="{
              name: RouteName.CREATE_EVENT,
              query: { actorId: selectedActor.id },
            }"
          >
            {{ $t("Pick") }}
          </b-button>
        </footer>
      </div>
    </b-modal>
  </div>
</template>
<script lang="ts">
import { Component, Prop, Vue } from "vue-property-decorator";
import { LOGGED_USER_MEMBERSHIPS } from "@/graphql/actor";
import { Paginate } from "@/types/paginate";
import { IMember } from "@/types/actor/member.model";
import { ActorType, MemberRole } from "@/types/enums";
import RouteName from "../../router/name";
import OrganizerPicker from "./OrganizerPicker.vue";
import OrganizerPickerWrapper from "./OrganizerPickerWrapper.vue";
import { IActor, IGroup, IPerson } from "../../types/actor";
import { CURRENT_ACTOR_CLIENT } from "../../graphql/actor";

@Component({
  components: { OrganizerPicker, OrganizerPickerWrapper },
  apollo: {
    groupMemberships: {
      query: LOGGED_USER_MEMBERSHIPS,
      update: (data) => data.loggedUser.memberships,
    },
    currentActor: CURRENT_ACTOR_CLIENT,
  },
})
export default class CreateEventDialoge extends Vue {
  @Prop({ type: Object, required: false }) value!: IActor;

  @Prop({ type: Object, required: false }) orgActor!: IActor;

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
  pickActor(): void {
    this.isComponentModalActive = false;
  }

  get selectedActor(): IActor | undefined {
    if (this.value?.id) {
      return this.value;
    }
    if (this.currentActor) {
      return this.currentActor;
    }
    return undefined;
  }

  set selectedActor(selectedActor: IActor | undefined) {
    this.$emit("input", selectedActor);
  }

  async relay(group: IGroup): Promise<void> {
    this.selectedActor = group;
  }

  get organizerActor(): IActor {
    if (this.orgActor) {
      return this.orgActor;
    }
    return this.currentActor;
  }

  set organizerActor(actor: IActor) {
    if (actor?.type === ActorType.GROUP) {
      this.orgActor = actor as IGroup;
    } else {
      this.orgActor = actor;
    }
  }
}
</script>
