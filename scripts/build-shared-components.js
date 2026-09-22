import { mkdir, writeFile } from "node:fs/promises";
import { gzipSync } from "node:zlib";
import { build } from "esbuild";
import externalGlobalPluginModule from "esbuild-plugin-external-global";
import postcss from "postcss";
import prefixSelector from "postcss-prefix-selector";

const outputFile = "assets/vendor/shared_components/shared_components-runtime.js";
const maxGzipBytes = 10 * 1024 * 1024;
const { externalGlobalPlugin } = externalGlobalPluginModule;

async function scopeCss(css) {
  const result = await postcss([
    prefixSelector({
      prefix: ".ea-shared-components-scope",
      transform(prefix, selector, prefixedSelector) {
        return selector === ":root" ? prefix : prefixedSelector;
      },
    }),
  ]).process(css, { from: undefined });

  return result.css;
}

const result = await build({
  bundle: true,
  entryPoints: ["react-src/shared_components/index.tsx"],
  format: "iife",
  globalName: "EaSharedComponentsRuntime",
  loader: { ".css": "css" },
  minify: true,
  outfile: outputFile,
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

const cssFile = result.outputFiles.find((file) => file.path.endsWith(".css"));
const javascriptFile = result.outputFiles.find((file) => file.path.endsWith(".js"));
if (!cssFile || !javascriptFile) {
  throw new Error("The shared components build did not emit both JavaScript and CSS.");
}

const css = await scopeCss(cssFile.text);
const styleLoader = `(()=>{if(document.querySelector('style[data-ea-shared-components-styles="true"]'))return;const style=document.createElement("style");style.dataset.eaSharedComponentsStyles="true";style.textContent=${JSON.stringify(css)};document.head.append(style)})();`;

await mkdir("assets/vendor/shared_components", { recursive: true });
const output = `${styleLoader}\n${javascriptFile.text}`;
const gzipBytes = gzipSync(output).byteLength;
if (gzipBytes > maxGzipBytes) {
  throw new Error(
    `Shared components runtime is ${gzipBytes} bytes gzip, exceeding the ${maxGzipBytes}-byte budget.`,
  );
}

await writeFile(outputFile, output);