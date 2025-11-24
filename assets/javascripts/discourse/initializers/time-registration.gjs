import { withPluginApi } from "discourse/lib/plugin-api";
import TimeRegistrationSmallActionPost from "../components/time-registration-small-action-post";

function initPlugin(api) {
  console.log("IPA");
  const siteSettings = api.container.lookup("service:site-settings");

  if (!siteSettings.time_registration_enabled) {
    return;
  }

  // Register the icon for the small action
  api.addPostSmallActionIcon("time_registration", "stopwatch");

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