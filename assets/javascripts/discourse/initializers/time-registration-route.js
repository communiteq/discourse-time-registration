import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("0.8", (api) => {
  api.registerConnectorClass("user-profile-primary", "time-registration-report", {
    shouldRender(args, component) {
      return component.currentUser && component.currentUser.admin; // Or check group
    }
  });
});