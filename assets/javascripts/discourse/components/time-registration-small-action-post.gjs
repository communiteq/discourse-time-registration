import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";
import { action } from "@ember/object";
import { service } from "@ember/service";
import I18n from "discourse-i18n";
import { autoUpdatingRelativeAge } from "discourse/lib/formatter";
import DButton from "discourse/components/d-button";
import TimeRegistrationEdit from "./modal/time-registration-edit";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class TimeRegistrationSmallActionPost extends Component {
  @service currentUser;
  @service modal;

  formatDuration(seconds) {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}`;
  }

  get canEdit() {
    if (!this.currentUser) return false;
    return this.currentUser.admin || this.currentUser.id === this.args.post.user_id;
  }

  get userLink() {
    const username = this.args.post.username;
    if (!username) {
      return "";
    }
    return `<a class="mention" href="/u/${username}">@${username}</a>`;
  }

  get description() {
    const post = this.args.post;
    const customFields = post.custom_fields || {};

    // Retrieve values from root (if serialized) or custom_fields
    const description = post.time_registration_description || customFields.time_registration_description || I18n.t("time_registration.no_description");
    const amount = post.time_registration_amount || customFields.time_registration_amount;
    const start = post.time_registration_start || customFields.time_registration_start;

    let message = "";

    if (amount) {
      // Case 1: Work is finished (amount exists)
      const durationStr = this.formatDuration(amount);
      message = I18n.t("time_registration.ended_action", {
        description: description,
        duration: durationStr
      });
    } else if (start) {
      // Case 2: Work is in progress (start exists, no amount)
      const dt = new Date(start * 1000);
      const when = autoUpdatingRelativeAge(dt, { format: "medium-with-ago" });
      message = I18n.t("time_registration.started_action_with_time", {
        description: description,
        when: when
      });
    } else {
      // Fallback
      message = description;
    }

    return htmlSafe(`${this.userLink} ${message}`);
  }

  @action
  edit() {
    const post = this.args.post;

    this.modal.show(TimeRegistrationEdit, {
      model: {
        post: post,
        save: (description, minutes) => {
          ajax("/time-registration/update", {
            type: "PUT",
            data: { post_id: post.id, description, duration: minutes },
          })
          .then(() => {
             // Update local model for immediate feedback
             // We need to update both root properties (if used) and custom_fields
             if (post.custom_fields) {
                 post.custom_fields.time_registration_description = description;
                 post.custom_fields.time_registration_amount = minutes * 60;
             }
             // Force a re-render by notifying property change if possible,
             // or relying on Glimmer tracking if we were tracking these.
             // Since post properties aren't tracked deep inside custom_fields usually,
             // we might need to trigger a refresh or just set the properties directly on the post object
             // if our component reads from there.
             post.set("time_registration_description", description);
             post.set("time_registration_amount", minutes * 60);
          })
          .catch(popupAjaxError);
        }
      },
    });
  }

  <template>
    <span class="time-registration-content">
      {{this.description}}
      {{#if this.canEdit}}
        <DButton
          class="btn-flat time-registration-edit-btn"
          @icon="pencil"
          @action={{this.edit}}
          @title="time_registration.edit"
        />
      {{/if}}
    </span>
  </template>
}