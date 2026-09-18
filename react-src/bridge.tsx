import React from "react";
import * as ReactDOM from "react-dom";
import { createRoot, type Root } from "react-dom/client";

export type ReactBridgeProps = {
  currentUser: {
    id: number;
    username: string;
  } | null;
  componentProps?: Record<string, unknown>;
};

export type ReactMountOptions = ReactBridgeProps & {
  component: string;
};

export type ReactBridge = {
  mount: (element: HTMLElement, options: ReactMountOptions) => () => void;
  register: (name: string, component: React.ComponentType<ReactBridgeProps>) => void;
};

const mountedRoots = new WeakMap<HTMLElement, Root>();
const components: Record<string, React.ComponentType<ReactBridgeProps>> = {};

function register(name: string, component: React.ComponentType<ReactBridgeProps>) {
  components[name] = component;
}

function render(root: Root, options: ReactMountOptions) {
  const Component = components[options.component];
  if (!Component) {
    throw new Error(`React feature is not registered: ${options.component}`);
  }

  root.render(<Component {...options} />);
}

function mount(element: HTMLElement, options: ReactMountOptions) {
  const existingRoot = mountedRoots.get(element);
  if (existingRoot) {
    render(existingRoot, options);
    return () => unmount(element, existingRoot);
  }

  const root = createRoot(element);
  mountedRoots.set(element, root);
  render(root, options);

  return () => unmount(element, root);
}

function unmount(element: HTMLElement, root: Root) {
  if (mountedRoots.get(element) !== root) {
    return;
  }

  root.unmount();
  mountedRoots.delete(element);
}

const bridge: ReactBridge = { mount, register };

window.React = React;
window.ReactDOM = ReactDOM;
window.DiscourseReactHybrid = bridge;
window.DiscourseReactJsxRuntime = {
  Fragment: React.Fragment,
  jsx: React.createElement,
  jsxs: React.createElement,
  jsxDEV: React.createElement,
};

export default bridge;