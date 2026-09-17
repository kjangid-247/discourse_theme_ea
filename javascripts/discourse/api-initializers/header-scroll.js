import { apiInitializer } from "discourse/lib/api";

const THRESHOLD = 60;

export default apiInitializer(() => {
  let ticking = false;

  const update = () => {
    document.documentElement.classList.toggle(
      "ea-header-scrolled",
      window.scrollY > THRESHOLD
    );
    ticking = false;
  };

  const onScroll = () => {
    if (!ticking) {
      ticking = true;
      window.requestAnimationFrame(update);
    }
  };

  window.addEventListener("scroll", onScroll, { passive: true });
  update();
});
