import loadSharedComponentsRuntime from "./load-shared-components-runtime";

const featureAssets = {
  counter: "react-counter",
};
const featurePromises = new Map();

export default function loadReactComponent(name) {
  const assetKey = featureAssets[name];
  if (!assetKey) {
    return Promise.reject(new Error(`Unknown React feature: ${name}`));
  }

  if (featurePromises.has(name)) {
    return featurePromises.get(name);
  }

  const promise = loadSharedComponentsRuntime()
    .then(
      () =>
        new Promise((resolve, reject) => {
          const source = settings.theme_uploads[assetKey];
          if (!source) {
            reject(new Error(`The ${name} React feature asset is unavailable.`));
            return;
          }

          const script = document.createElement("script");
          script.src = source;
          script.async = true;
          script.dataset.eaReactFeature = name;
          script.onload = () => resolve(window.DiscourseReactHybrid);
          script.onerror = () => reject(new Error(`Unable to load the ${name} React feature.`));
          document.head.append(script);
        }),
    )
    .catch((error) => {
      featurePromises.delete(name);
      throw error;
    });

  featurePromises.set(name, promise);
  return promise;
}