import { mkdir, writeFile } from "node:fs/promises";
import { dirname } from "node:path";
import { build } from "esbuild";
import externalGlobalPluginModule from "esbuild-plugin-external-global";
import { features } from "../react-src/features/manifest.js";

const { externalGlobalPlugin } = externalGlobalPluginModule;

for (const feature of Object.values(features)) {
  const result = await build({
    bundle: true,
    entryPoints: [feature.entryPoint],
    format: "iife",
    globalName: "EaReactFeature",
    minify: true,
    outfile: feature.outputFile,
    platform: "browser",
    plugins: [
      externalGlobalPlugin({
        react: "window.React",
        "react-dom": "window.ReactDOM",
        "react/jsx-runtime": "window.DiscourseReactJsxRuntime",
        "react/jsx-dev-runtime": "window.DiscourseReactJsxRuntime",
      }),
    ],
    write: false,
  });

  const javascriptFile = result.outputFiles.find((file) => file.path.endsWith(".js"));
  if (!javascriptFile) {
    throw new Error(`The ${feature.assetKey} build did not emit JavaScript.`);
  }

  await mkdir(dirname(feature.outputFile), { recursive: true });
  await writeFile(feature.outputFile, javascriptFile.text);
}