import Component from "@glimmer/component";
import { service } from "@ember/service";
// eslint-disable-next-line discourse/ui-kit-imports -- ui-kit paths not yet present in targeted Discourse (<= 2026.4); use stable path
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class EaBreadcrumbs extends Component {
  @service router;
  @service discovery;
  @service header;

  get routeName() {
    return this.router.currentRouteName;
  }

  get isTopicRoute() {
    return this.routeName?.startsWith("topic.");
  }

  get isAdminRoute() {
    return this.routeName?.startsWith("admin");
  }

  get routeChain() {
    const chain = [];
    let route = this.router.currentRoute;
    while (route && route.name) {
      chain.unshift(route);
      route = route.parent;
    }
    return chain;
  }

  get category() {
    if (this.isTopicRoute) {
      return this.header.topicInfo?.category ?? null;
    }
    return this.discovery.category ?? null;
  }

  get categoryBreadcrumbs() {
    const category = this.category;
    if (!category) {
      return [];
    }

    return [...category.predecessors]
      .reverse()
      .concat([category])
      .map((cat) => ({
        label: cat.name,
        url: cat.url,
        isCategory: true,
      }));
  }

  get routeNameBreadcrumbs() {
    const crumbs = [];
    let previousLocalName = null;

    for (const route of this.routeChain) {
      const localName = route.localName;
      if (!localName) {
        continue;
      }

      if (
        localName === "application" ||
        localName === "index" ||
        localName === "show" ||
        localName === "admin" ||
        localName === "discovery"
      ) {
        previousLocalName = localName;
        continue;
      }

      let label = localName;

      if (/^admin[A-Z]/.test(label)) {
        label = label.slice("admin".length);
      }

      if (previousLocalName && label.length > previousLocalName.length) {
        const head = label.slice(0, previousLocalName.length);
        const nextChar = label.charAt(previousLocalName.length);
        if (
          head.toLowerCase() === previousLocalName.toLowerCase() &&
          /[A-Z]/.test(nextChar)
        ) {
          label = label.slice(previousLocalName.length);
        }
      }

      if (!label) {
        previousLocalName = localName;
        continue;
      }

      const formatted = label
        .replace(/([a-z])([A-Z])/g, "$1 $2")
        .replace(/^./, (c) => c.toUpperCase());

      let url;
      try {
        url = this.router.urlFor(route.name);
      } catch {
        url = this.isAdminRoute ? "/admin" : "/";
      }

      crumbs.push({ label: formatted, url, isRouteName: true });
      previousLocalName = localName;
    }

    return crumbs;
  }

  get adminBreadcrumb() {
    return {
      label: i18n(themePrefix("breadcrumbs.admin")),
      url: "/admin",
    };
  }

  get breadcrumbs() {
    let tail;
    if (this.categoryBreadcrumbs.length > 0) {
      tail = this.categoryBreadcrumbs;
    } else if (this.routeNameBreadcrumbs.length > 0) {
      tail = this.routeNameBreadcrumbs;
    } else {
      tail = [];
    }

    const middle = this.isAdminRoute ? [this.adminBreadcrumb] : [];
    const crumbs = [...middle, ...tail];

    if (crumbs.length && !this.isTopicRoute) {
      crumbs[crumbs.length - 1] = {
        ...crumbs[crumbs.length - 1],
        isActive: true,
      };
    }
    return crumbs;
  }

  get shouldRender() {
    return !this.discovery.custom && this.breadcrumbs.length >= 1;
  }

  <template>
    {{#if this.shouldRender}}
      <nav class="ea-breadcrumbs" aria-label="Breadcrumb">
        <ol class="ea-breadcrumbs__inner">
          {{#each this.breadcrumbs as |crumb|}}
            <li
              class="ea-breadcrumbs__item
                {{if crumb.isActive '--active'}}
                {{if crumb.isCategory '--category'}}"
            >
              <span class="ea-breadcrumbs__separator" aria-hidden="true">
                {{icon "chevron-right"}}
              </span>
              {{#if crumb.isActive}}
                <span class="ea-breadcrumbs__current" aria-current="page">
                  {{crumb.label}}
                </span>
              {{else if crumb.url}}
                <a href={{crumb.url}} class="ea-breadcrumbs__link">
                  {{crumb.label}}
                </a>
              {{else}}
                <span class="ea-breadcrumbs__link">{{crumb.label}}</span>
              {{/if}}
            </li>
          {{/each}}
        </ol>
      </nav>
    {{/if}}
  </template>
}
