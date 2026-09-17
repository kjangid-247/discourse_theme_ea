import { apiInitializer } from "discourse/lib/api";
import EaBreadcrumbs from "../components/ea-breadcrumbs";

export default apiInitializer((api) => {
  if (settings.show_breadcrumbs) {
    api.renderInOutlet("before-header-panel", EaBreadcrumbs);
  }
});
