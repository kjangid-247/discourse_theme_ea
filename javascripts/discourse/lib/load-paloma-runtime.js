import loadReactRuntime from "./load-react-runtime";

let palomaRuntimePromise;

export default function loadPalomaRuntime() {
  if (palomaRuntimePromise) {
    return palomaRuntimePromise;
  }

  palomaRuntimePromise = loadReactRuntime()
    .then(
      () =>
        new Promise((resolve, reject) => {
          const source = settings.theme_uploads["paloma-runtime"];
          if (!source) {
            reject(new Error("The Paloma runtime theme asset is unavailable."));
            return;
          }

          const script = document.createElement("script");
          script.src = source;
          script.async = true;
          script.dataset.eaPalomaRuntime = "true";
          script.onload = () => {
            if (window.DiscourseReactHybrid) {
              resolve(window.DiscourseReactHybrid);
            } else {
              reject(new Error("The Paloma runtime did not retain the React bridge."));
            }
          };
          script.onerror = () => reject(new Error("Unable to load the Paloma runtime."));
          document.head.append(script);
        }),
    )
    .catch((error) => {
      palomaRuntimePromise = null;
      throw error;
    });

  return palomaRuntimePromise;
}