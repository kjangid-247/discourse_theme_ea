import { Button } from "@paloma/core-ui/components/Button";
import { ThemeProvider } from "@paloma/core-ui/components/ThemeProvider";
import { Carousel } from "@paloma/core-ui/components/Carousel";
// @ts-ignore
import "@paloma/core-ui/styles.css";
// @ts-ignore
import "@paloma/layout/styles.css";

const bridge = window.DiscourseReactHybrid;
if (!bridge) {
  throw new Error("The React runtime must load before the Paloma runtime.");
}

window.EaPaloma = { Button, ThemeProvider ,Carousel};