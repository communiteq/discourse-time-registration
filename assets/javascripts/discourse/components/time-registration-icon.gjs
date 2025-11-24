import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import I18n from "discourse-i18n";
import DButton from "discourse/components/d-button";
import TimeRegistrationStart from "./modal/time-registration-start";

export default class TimeRegistrationIcon extends Component {
  @service currentUser;
  @service router;
  @service dialog;
  @service siteSettings;
  @service modal;

  @tracked isTracking = false;

  constructor() {
    super(...arguments);
    if (this.currentUser) {
      this.isTracking = !!this.currentUser.custom_fields.active_time_registration_post_id;
    }
  }

  get canTrack() {
    if (!this.currentUser || !this.siteSettings.time_registration_enabled) {
      return false;
    }

    if (this.currentUser.admin) {
      return true;
    }

    const allowedGroups = (this.siteSettings.time_registration_groups || "")
      .split("|")
      .map((id) => parseInt(id, 10));

    const userGroups = this.currentUser.groups || [];
    return userGroups.some((g) => allowedGroups.includes(g.id));
  }

  get iconClass() {
    console.log(this.isTracking ? "True" : "False");
    return this.isTracking ? "time-registration-icon tracking-active" : "time-registration-icon";
  }

  @action
  toggle() {
    if (!this.isTracking) {
      let topicId = null;
      const currentRoute = this.router.currentRoute;

      if (currentRoute && currentRoute.name.startsWith("topic")) {
        topicId = currentRoute.params?.id || currentRoute.attributes?.id;

        if (!topicId && currentRoute.parent) {
          topicId = currentRoute.parent.params?.id || currentRoute.parent.attributes?.id;
        }
      }

      if (!topicId) {
        this.dialog.alert(I18n.t("time_registration.must_be_in_topic"));
        return;
      }

      this.modal.show(TimeRegistrationStart, {
        model: {
          topicId: topicId,
          save: (description) => this.toggleTimer(topicId, description),
        },
      });
    } else {
      this.toggleTimer(null, null);
    }
  }

  toggleTimer(topicId, description) {
    ajax("/time-registration/toggle", {
      type: "POST",
      data: { topic_id: topicId, description },
    })
      .then((result) => {
        // Update local tracked state immediately for UI update
        this.isTracking = result.active;

        // Sync back to currentUser model just in case other parts of app need it
        const val = result.active ? result.post_id : null;
        this.currentUser.custom_fields.active_time_registration_post_id = val;
      })
      .catch(popupAjaxError);
  }

  <template>
    {{#if this.canTrack}}
      <li class={{this.iconClass}}>
        <DButton
          class="icon btn-flat"
          @icon="stopwatch"
          @action={{this.toggle}}
          @title="time_registration.title"
        />
      </li>
    {{/if}}
  </template>
}