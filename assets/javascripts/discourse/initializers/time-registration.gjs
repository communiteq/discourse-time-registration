import { withPluginApi } from "discourse/lib/plugin-api";
import TimeRegistrationSmallActionPost from "../components/time-registration-small-action-post";
import { i18n } from "discourse-i18n";

function initPlugin(api) {
  const siteSettings = api.container.lookup("service:site-settings");

  if (!siteSettings.time_registration_enabled) {
    return;
  }

  api.addCommunitySectionLink({
    name: "time_registration.title",
    route: "timeRegistrationReport",
    title: i18n("time_registration.title"),
    text: i18n("time_registration.title"),
    icon: "far-clock",
  });

  // Register the icon for the small action
  api.addPostSmallActionIcon("time_registration", "far-clock");

  // register custom class for styling
  api.registerValueTransformer(
    "post-small-action-class",
    ( {value, context} ) => {
      return context?.post?.action_code === "time_registration" ? "time-registration-post" : value;
    }
  );

  // Register the custom component to render the content
  api.registerValueTransformer(
    "post-small-action-custom-component",
    ( {value, context: { code, post } } ) => {
      return post?.action_code === "time_registration" ?
        TimeRegistrationSmallActionPost : value;
    }
  );
}

export default {
  name: "time-registration",
  initialize() {
    withPluginApi("0.8.8", initPlugin);
  },
};