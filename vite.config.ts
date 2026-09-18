import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [react()],
  define: {
    "process.env.NODE_ENV": JSON.stringify("production"),
  },
  build: {
    emptyOutDir: false,
    lib: {
      entry: "react-src/bridge.tsx",
      formats: ["iife"],
      name: "DiscourseReactHybridBundle",
      fileName: () => "react-runtime.js",
    },
    outDir: "assets/vendor/react",
    rollupOptions: {
      output: {
        inlineDynamicImports: true,
      },
    },
  },
});