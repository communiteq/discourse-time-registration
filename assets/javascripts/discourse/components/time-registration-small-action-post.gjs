import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";
import I18n from "discourse-i18n";
import { autoUpdatingRelativeAge } from "discourse/lib/formatter";
import { duration } from "discourse/lib/formatter";

export default class TimeRegistrationSmallActionPost extends Component {
  get description() {
    const post = this.args.post;
    // Check root property first, then custom_fields
    const description = post.time_registration_description || post.custom_fields?.time_registration_description || I18n.t("time_registration.no_description");
    const startTime = post.time_registration_start || post.custom_fields?.time_registration_start;
    const endTime = post.time_registration_end || post.custom_fields?.time_registration_end;

    if (endTime) {
      // Finished
      const durationSeconds = endTime - startTime;
      const durationStr = duration(durationSeconds);

      return htmlSafe(I18n.t("time_registration.ended_action", {
        description: description,
        duration: durationStr
      }));
    } else {
      // In progress
      // We can show "Started working: [description] - [relative time]"
      const dt = new Date(startTime * 1000); // unix timestamp to JS date
      const when = autoUpdatingRelativeAge(dt, { format: "medium-with-ago" });

      return htmlSafe(I18n.t("time_registration.started_action_with_time", {
        description: description,
        when: when
      }));
    }
  }

  <template>
    {{this.description}}
  </template>
}