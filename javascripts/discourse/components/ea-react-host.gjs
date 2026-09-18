import Component from "@glimmer/component";
import { modifier } from "ember-modifier";
import loadReactComponent from "../lib/load-react-component";

export default class EaReactHost extends Component {
  mountReact = modifier((element) => {
    let cleanup;
    let destroyed = false;

    const loadComponent = loadReactComponent(this.args.feature);

    loadComponent
      .then((bridge) => {
        if (destroyed) {
          return;
        }

        cleanup = bridge.mount(element, {
          component: this.args.component,
          componentProps: this.args.componentProps ?? {},
          currentUser: this.args.currentUser,
        });
      })
      .catch((error) => {
        // Loading failures should not prevent the Discourse page from rendering.
        console.error("Unable to mount the React theme component.", error);
      });

    return () => {
      destroyed = true;
      cleanup?.();
    };
  });

  <template>
    <div class="ea-react-host" {{this.mountReact}}></div>
  </template>
}