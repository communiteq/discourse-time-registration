import { withPluginApi } from "discourse/lib/plugin-api";
import TimeRegistrationIcon from "../components/time-registration-icon";

export default {
  name: "time-registration-icon",

  initialize(container) {
    withPluginApi("0.8", (api) => {
      const currentUser = api.getCurrentUser();
      const siteSettings = container.lookup("service:site-settings");

      if (!currentUser || !siteSettings.time_registration_enabled) {
        return;
      }

      // Check group membership
      const allowedGroups = (siteSettings.time_registration_groups || "")
        .split("|")
        .map((id) => parseInt(id, 10));

      const userGroups = currentUser.groups.map((g) => g.id);
      const canTrack = currentUser.admin || allowedGroups.some((id) => userGroups.includes(id));

      if (!canTrack) {
        return;
      }

      api.headerIcons.add("time-registration", TimeRegistrationIcon);
    });
  },
};