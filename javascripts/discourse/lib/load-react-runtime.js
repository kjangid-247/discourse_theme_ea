let runtimePromise;

export default function loadReactRuntime() {
  if (window.DiscourseReactHybrid) {
    return Promise.resolve(window.DiscourseReactHybrid);
  }

  if (runtimePromise) {
    return runtimePromise;
  }

  const source = settings.theme_uploads["react-runtime"];
  if (!source) {
    return Promise.reject(new Error("The React runtime theme asset is unavailable."));
  }

  runtimePromise = new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = source;
    script.async = true;
    script.dataset.eaReactRuntime = "true";
    script.onload = () => {
      if (window.DiscourseReactHybrid) {
        resolve(window.DiscourseReactHybrid);
      } else {
        reject(new Error("The React runtime did not expose its browser bridge."));
      }
    };
    script.onerror = () => reject(new Error("Unable to load the React runtime."));
    document.head.append(script);
  }).catch((error) => {
    runtimePromise = null;
    throw error;
  });

  return runtimePromise;
}