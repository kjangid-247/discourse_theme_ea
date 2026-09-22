import type { ElementType } from "react";

export type SharedComponents = {
  Button: ElementType;
  ThemeProvider: ElementType;
  Carousel: ElementType;
};

export default function getSharedComponents(): SharedComponents {
  if (!window.EaSharedComponents) {
    throw new Error("The shared components runtime must load before this React feature.");
  }

  return window.EaSharedComponents;
}