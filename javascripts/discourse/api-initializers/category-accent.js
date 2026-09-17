import { apiInitializer } from "discourse/lib/api";

export default apiInitializer((api) => {
  const discovery = api.container.lookup("service:discovery");
  const router = api.container.lookup("service:router");
  const root = document.documentElement;

  let currentColor = null;

  api.onPageChange(() => {
    let category = discovery.category;

    if (!category && router.currentRouteName?.startsWith("topic.")) {
      const topic = api.container.lookup("controller:topic")?.model;

      if (!topic) {
        return;
      }

      category = topic.category;
    }

    const color = category?.color ? `#${category.color}` : null;

    root.classList.toggle(
      "ea-gradient",
      discovery.custom || !!discovery.category
    );

    if (color === currentColor) {
      return;
    }
    currentColor = color;

    root.classList.toggle("ea-category-themed", !!color);

    if (color) {
      root.style.setProperty("--ea-category-color", color);
    } else {
      root.style.removeProperty("--ea-category-color");
    }
  });
});
