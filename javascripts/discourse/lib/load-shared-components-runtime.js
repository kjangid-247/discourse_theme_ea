import loadReactRuntime from "./load-react-runtime";

let sharedComponentsRuntimePromise;

export default function loadSharedComponentsRuntime() {
  if (sharedComponentsRuntimePromise) {
    return sharedComponentsRuntimePromise;
  }

  sharedComponentsRuntimePromise = loadReactRuntime()
    .then(
      () =>
        new Promise((resolve, reject) => {
          const source = settings.theme_uploads["shared_components-runtime"];
          if (!source) {
            reject(new Error("The shared components runtime theme asset is unavailable."));
            return;
          }

          const script = document.createElement("script");
          script.src = source;
          script.async = true;
          script.dataset.eaSharedComponentsRuntime = "true";
          script.onload = () => {
            if (window.DiscourseReactHybrid) {
              resolve(window.DiscourseReactHybrid);
            } else {
              reject(new Error("The shared components runtime did not retain the React bridge."));
            }
          };
          script.onerror = () => reject(new Error("Unable to load the shared components runtime."));
          document.head.append(script);
        }),
    )
    .catch((error) => {
      sharedComponentsRuntimePromise = null;
      throw error;
    });

  return sharedComponentsRuntimePromise;
}