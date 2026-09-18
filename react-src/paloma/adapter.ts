import type { ElementType } from "react";

export type PalomaComponents = {
  Button: ElementType;
  ThemeProvider: ElementType;
  Carousel: ElementType;
};

export default function getPaloma(): PalomaComponents {
  if (!window.EaPaloma) {
    throw new Error("The Paloma runtime must load before this React feature.");
  }

  return window.EaPaloma;
}