import CounterWidget from "./CounterWidget";

const bridge = window.DiscourseReactHybrid;
if (!bridge) {
  throw new Error("The React runtime must load before a React feature.");
}

bridge.register("counter", CounterWidget);