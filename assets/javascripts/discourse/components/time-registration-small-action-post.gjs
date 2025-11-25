import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";
import I18n from "discourse-i18n";
import { autoUpdatingRelativeAge } from "discourse/lib/formatter";
import avatar from "discourse/helpers/avatar";

export default class TimeRegistrationSmallActionPost extends Component {
  formatDuration(seconds) {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    return `${h.toString()}:${m.toString().padStart(2, '0')}`;
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

  <template>
    {{this.description}}
  </template>
}