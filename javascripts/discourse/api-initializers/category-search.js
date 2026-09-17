import { apiInitializer } from "discourse/lib/api";
import EaCategorySearch from "../components/ea-category-search";

export default apiInitializer((api) => {
  api.renderInOutlet("category-heading", EaCategorySearch);
});
