import { mkdir, writeFile } from "node:fs/promises";
import { gzipSync } from "node:zlib";
import { build } from "esbuild";
import externalGlobalPluginModule from "esbuild-plugin-external-global";
import postcss from "postcss";
import prefixSelector from "postcss-prefix-selector";

const outputFile = "assets/vendor/paloma/paloma-runtime.js";
const maxGzipBytes = 10 * 1024 * 1024;
const { externalGlobalPlugin } = externalGlobalPluginModule;

async function scopeCss(css) {
  const result = await postcss([
    prefixSelector({
      prefix: ".ea-paloma-scope",
      transform(prefix, selector, prefixedSelector) {
        return selector === ":root" ? prefix : prefixedSelector;
      },
    }),
  ]).process(css, { from: undefined });

  return result.css;
}

const result = await build({
  bundle: true,
  entryPoints: ["react-src/paloma/index.tsx"],
  format: "iife",
  globalName: "EaPalomaRuntime",
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
  throw new Error("The Paloma build did not emit both JavaScript and CSS.");
}

const css = await scopeCss(cssFile.text);
const styleLoader = `(()=>{if(document.querySelector('style[data-ea-paloma-styles="true"]'))return;const style=document.createElement("style");style.dataset.eaPalomaStyles="true";style.textContent=${JSON.stringify(css)};document.head.append(style)})();`;

await mkdir("assets/vendor/paloma", { recursive: true });
const output = `${styleLoader}\n${javascriptFile.text}`;
const gzipBytes = gzipSync(output).byteLength;
if (gzipBytes > maxGzipBytes) {
  throw new Error(
    `Paloma runtime is ${gzipBytes} bytes gzip, exceeding the ${maxGzipBytes}-byte budget.`,
  );
}

await writeFile(outputFile, output);