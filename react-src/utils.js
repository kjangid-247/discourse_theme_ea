/** Discourse's active color scheme, read from the `--scheme-type` custom property. */
export function getDiscourseColorMode() {
  const schemeType = getComputedStyle(document.documentElement)
    .getPropertyValue("--scheme-type")
    .trim();

  return schemeType === "dark" ? "dark" : "light";
}

/** Notifies `callback` whenever Discourse's rendered color scheme changes, including OS-driven "auto" mode.
 * @param {(mode: "light" | "dark") => void} callback
 */
export function subscribeToDiscourseColorMode(callback) {
  const observer = new MutationObserver(() => {
    callback(getDiscourseColorMode());
  });

  for (const target of [document.documentElement, document.body].filter(Boolean)) {
    observer.observe(target, {
      attributes: true,
      attributeFilter: ["class", "data-color-scheme", "data-theme", "style"],
    });
  }

  const colorSchemeQuery = window.matchMedia("(prefers-color-scheme: dark)");
  const onColorSchemeChange = () => callback(getDiscourseColorMode());
  colorSchemeQuery.addEventListener("change", onColorSchemeChange);

  return () => {
    observer.disconnect();
    colorSchemeQuery.removeEventListener("change", onColorSchemeChange);
  };
}
