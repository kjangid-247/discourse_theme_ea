import type { ReactBridge } from "./bridge";
declare module "@paloma/core-ui/styles.css";

declare global {
  interface Window {
    React?: typeof import("react");
    ReactDOM?: typeof import("react-dom");
    DiscourseReactHybrid?: ReactBridge;
    DiscourseReactJsxRuntime?: {
      Fragment: typeof import("react").Fragment;
      jsx: typeof import("react").createElement;
      jsxs: typeof import("react").createElement;
      jsxDEV: typeof import("react").createElement;
    };
    EaSharedComponents?: {
      Button: React.ElementType;
      ThemeProvider: React.ElementType;
      Carousel: React.ElementType;
    };
  }
}

export {};