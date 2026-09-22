import { watch } from "node:fs";
import { spawn } from "node:child_process";

const timers = new Map();

function run(label, args) {
  const child = spawn(process.execPath, args, { stdio: "inherit" });
  child.on("error", (error) => {
    console.error(`Unable to run ${label}:`, error);
  });
}

function schedule(label, args) {
  clearTimeout(timers.get(label));
  timers.set(label, setTimeout(() => run(label, args), 100));
}

function watchDirectory(directory, label, args) {
  watch(directory, { recursive: true }, (_event, fileName) => {
    if (fileName?.endsWith(".tsx") || fileName?.endsWith(".ts") || fileName?.endsWith(".js")) {
      schedule(label, args);
    }
  });
}

const sharedComponentsBuild = ["scripts/build-shared-components.js"];
const featureBuild = ["scripts/build-react-features.js"];
const reactWatch = ["node_modules/vite/bin/vite.js", "build", "--watch"];

run("build:shared_components", sharedComponentsBuild);
run("build:features", featureBuild);
const reactWatcher = spawn(process.execPath, reactWatch, { stdio: "inherit" });
watchDirectory("react-src/shared_components", "build:shared_components", sharedComponentsBuild);
watchDirectory("react-src/features", "build:features", featureBuild);

function stop() {
  reactWatcher.kill();
  process.exit();
}

process.on("SIGINT", stop);
process.on("SIGTERM", stop);