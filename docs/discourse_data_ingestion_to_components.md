# Discourse Data Integration into React Theme Components

## 1. Purpose

This document is an engineering reference for passing **Discourse-owned data into React features implemented inside a Discourse Theme or Theme Component**.

The project uses a hybrid architecture:

```text
Discourse Core
  Ember / Glimmer / services / Store / APIs
              |
              | acquire + derive + normalize
              v
        GJS Theme Layer
              |
              | explicit props + callbacks
              v
          EaReactHost
              |
              v
        React Bridge
              |
              v
        React Feature
```

### Core rule

> **Discourse/Ember owns access to Discourse state. The GJS layer acquires and normalizes that state, then passes a small explicit data contract into React.**

React should normally receive plain values, arrays, objects, and callbacks—not live Ember services, Ember Data models, or Discourse container objects.

This document intentionally covers the practical ways a theme can obtain data. They are not all equally stable: prefer theme-facing APIs and existing page context first, and isolate core-internal mechanisms when they are unavoidable.

---

# 2. Project Architecture and Repository Context

The current setup has a **full Discourse Core checkout** and a **separate EA Theme repository**.

```text
Discourse Core repository
├── Rails backend
├── Ember / Glimmer frontend
├── frontend services
├── Store / models
├── JS / Plugin API
├── JSON endpoints
└── UI Kit

EA Theme repository
├── Theme templates / CSS / JS
├── .gjs Glimmer connectors
├── EaReactHost
├── React bridge
└── React feature code
```

The repositories are separate, but at runtime the theme JavaScript executes inside the Discourse frontend application. The GJS layer can therefore consume the frontend state and APIs exposed by the running Discourse version.

The **Discourse Core checkout is the implementation source of truth for the exact version being developed against**. It is particularly useful for determining outlet arguments, services, Store patterns, API methods, routes, serializers, and internal module paths.

The important architectural distinction is:

```text
Discourse Core = owns application state and server APIs
EA Theme       = consumes/derives that state for theme features
React         = consumes an explicit contract from the theme layer
```

Repository separation therefore does **not** mean the React feature needs a separate data layer.

---

# 3. Data-Ingestion Strategy

When a React feature needs Discourse data, start with the closest existing source.

```text
1. Is the data already available to the current outlet/component?
       |
       +--> outlet args / component args

2. Is it owned by a frontend service?
       |
       +--> currentUser / site / siteSettings / router / etc.

3. Does the Theme/JS API expose the required information or lifecycle hook?
       |
       +--> current user / page changes / events / transformers / decorators

4. Is there already a JSON endpoint used by Discourse?
       |
       +--> ajax("/something.json")

5. Is the data represented by an Ember Data model?
       |
       +--> Store

6. Does the feature require data that Discourse does not expose?
       |
       +--> plugin/core endpoint

7. Only then consider core-internal mechanisms.
```

This order prevents unnecessary network requests and avoids coupling React directly to Discourse internals.

## The main data-source groups

| Group | Examples | Typical role |
|---|---|---|
| Context | outlet args, component args, route/content context | Data already available on the current screen |
| Services | `currentUser`, `site`, `router`, `store`, `appEvents` | Application state and frontend capabilities |
| Configuration | theme settings, uploads, `siteSettings` | Theme/site configuration and assets |
| JS API | `api.getCurrentUser()`, page hooks, events, transformers | Theme/plugin extension points |
| JSON | `ajax()` + Discourse endpoints | Server-backed data |
| Store | Ember Data models and queries | Model-backed application data |
| Extension | model extensions, custom endpoints | Features requiring deeper integration |
| Internal | direct imports, container, bootstrap data, DOM | Last-resort/version-sensitive access |

---

# 4. Context Already Available to the Theme

These are the first mechanisms to check because the page may already have the required data.

## 4.1 Plugin outlet context

Discourse plugin outlets provide contextual arguments to content rendered at a particular outlet. The exact arguments depend on the outlet; there is no universal outlet-data schema.

Depending on the Discourse version and outlet, outlet data can be available through `@outletArgs` or as top-level component arguments.

### Example

```gjs
<PluginOutlet @name="topic-above-post-stream" as |outletArgs|>
  <EaReactHost
    @componentProps={{hash
      topic=outletArgs.topic
      currentUser=outletArgs.currentUser
    }}
  />
</PluginOutlet>
```

A theme component can also inspect the actual arguments supplied by the outlet and select only what React needs.

### Best use cases

- Topic/post/category/user context already present at the outlet.
- Avoiding a second request for data already loaded by the page.
- Building React features that are attached to a specific Discourse UI location.

### Important limitation

Outlet arguments are **context-specific**. Always inspect the actual outlet implementation for the Discourse version being used rather than assuming a field exists.

---

## 4.2 Component arguments and parent context

A GJS component can receive data from its parent and pass it through to React.

```gjs
<EaReactHost
  @componentProps={{hash
    topic=@topic
    category=@category
    user=@user
  }}
/>
```

This is useful when another Ember/Glimmer component already performed the work of loading or deriving the data.

### Preferred pattern

```text
Parent / Discourse context
        |
        v
GJS component
        |
        | select + normalize
        v
EaReactHost
        |
        v
React
```

Do not make React independently rediscover data that the parent component already owns.

---

## 4.3 Page and route context

Some data belongs to the current route rather than a specific outlet. A route/controller/component can expose that context to the GJS layer, which then passes the relevant fields to React.

Typical examples include:

- current topic
- current category
- current user/profile
- current search state
- route parameters
- pagination or page state

Use the route/page model when the required information is already part of the current screen's state.

---

## 4.4 Cooked post and content context

React features attached to cooked post content may receive information through Discourse's cooked-content extension mechanisms. A decorator/helper can obtain the relevant post and derive a small React payload.

Conceptually:

```text
Cooked post
   |
   v
Discourse content extension
   |
   | derive post/content data
   v
React host
   |
   v
React feature
```

This is preferable to parsing rendered HTML when the content extension API already provides the underlying post/context.

---

# 5. Discourse Frontend Services

GJS components can inject Discourse/Ember services and use them as the source of application state or frontend capabilities.

Common services relevant to React integration include:

```text
currentUser
site
siteSettings
router
store
appEvents
session
topicTrackingState
messageBus
notifications
search
sidebarState
```

The exact set of services depends on the Discourse version and the feature being implemented.

## Example

```gjs
import Component from "@glimmer/component";
import { service } from "@ember/service";

export default class ReactDataHost extends Component {
  @service currentUser;
  @service site;
  @service siteSettings;
  @service router;

  get reactProps() {
    return {
      user: this.currentUser
        ? {
            id: this.currentUser.id,
            username: this.currentUser.username,
            name: this.currentUser.name,
          }
        : null,
      site: {
        title: this.site.title,
      },
      settings: {
        enableFeature: this.siteSettings.enable_some_feature,
      },
      currentUrl: this.router.currentURL,
    };
  }
}
```

## Current user

`currentUser` is a frontend service and should normally be read at the GJS boundary.

```gjs
@service currentUser;
```

Anonymous visitors can have no current user, so React should receive `null` or another explicit anonymous representation rather than assuming a user always exists.

If the requirement is simply to obtain the current user through the Theme JS API, `api.getCurrentUser()` is covered separately in the JS API section. These are different access surfaces even though they describe the same application concept.

## Service rule

Do **not** pass the service itself into React:

```js
// Avoid
componentProps={{ currentUserService: this.currentUser }}
```

Instead, derive the fields React needs:

```js
const reactUser = this.currentUser
  ? {
      id: this.currentUser.id,
      username: this.currentUser.username,
      name: this.currentUser.name,
      avatarTemplate: this.currentUser.avatar_template,
    }
  : null;
```

This keeps the React boundary independent of Ember service behavior.

---

# 6. Theme Configuration and Assets

Not every input to React is application data. Theme configuration and assets are also useful inputs to a React feature.

## 6.1 Theme settings

Theme settings are declared in `settings.yml` / `settings.yaml` and can control feature behavior without changing JavaScript.

```yaml
my_react_feature_enabled:
  type: bool
  default: true

my_react_title:
  type: string
  default: "Topics"
```

The GJS/theme layer can read the settings and pass plain values to React.

```js
const props = {
  enabled: settings.my_react_feature_enabled,
  title: settings.my_react_title,
};
```

Use theme settings for **theme-owned configuration** such as feature flags, labels, display options, and theme-specific behavior.

## 6.2 Theme uploads

Theme uploads are primarily an asset mechanism rather than an application-data mechanism. They can provide images, fonts, and other static resources used by a React feature.

The React boundary should receive the resulting asset URL/path or use the theme asset in the normal frontend way rather than treating uploaded files as a substitute for Discourse application state.

## 6.3 Site settings

`siteSettings` exposes Discourse site configuration to frontend code.

```gjs
@service siteSettings;
```

Example:

```js
const reactConfig = {
  loginRequired: this.siteSettings.login_required,
  title: this.siteSettings.title,
};
```

### Theme setting vs site setting

```text
Theme setting
  = configuration owned by this theme

Site setting
  = configuration owned by the Discourse site/application
```

Use the appropriate source rather than copying site-wide configuration into theme settings.

---

# 7. Discourse JS API / Plugin API

The Discourse JS/Plugin API provides theme/plugin extension points without requiring direct access to every Ember implementation detail.

For React integration, the most relevant categories are:

- current user access
- page-change hooks
- application event hooks
- cooked-content decorators
- value transformers
- model extensions
- outlet/rendering APIs

## Current user through the API

```js
const user = api.getCurrentUser();
```

This is useful when code is already structured around an `apiInitializer` or another Plugin API extension.

## Page changes

A feature that needs to react to navigation can use the page-change lifecycle instead of repeatedly polling the DOM or issuing requests.

Conceptually:

```js
api.onPageChange((url, title) => {
  // derive/update state for the new page
});
```

The exact callback data and API surface should follow the Discourse version used by the project.

## Application events

The API can subscribe to Discourse application events. This is useful when the application already emits the event needed by the feature.

```js
api.onAppEvent("some-event", (data) => {
  // react to a Discourse event
});
```

## Cooked-content decorators

The API supports extending cooked content and attaching behavior to rendered post content. This is useful for React widgets embedded in or adjacent to post content.

## Transformers and model extension

The API also provides extension points for adding or transforming data exposed by Discourse models. Use these only when a feature genuinely needs model-level integration; for a simple React widget, outlet context, services, or an endpoint is usually simpler.

---

# 8. Discourse Ajax and JSON Endpoints

When the required data is not already available in the frontend, the most common server-backed path is:

```text
GJS / Theme JS
      |
      | ajax()
      v
Discourse JSON endpoint
      |
      v
Rails / application data
```

## Core helper

```js
import { ajax } from "discourse/lib/ajax";

const response = await ajax("/latest.json");
```

For the current project, this is a strong default for theme-owned data acquisition when an existing Discourse endpoint already exposes the required information.

## Example

```gjs
import Component from "@glimmer/component";
import { ajax } from "discourse/lib/ajax";

export default class ReactTopics extends Component {
  topics = [];

  async loadTopics() {
    const data = await ajax("/latest.json");

    this.topics = (data.topic_list?.topics || []).map((topic) => ({
      id: topic.id,
      title: topic.title,
      slug: topic.slug,
      postsCount: topic.posts_count,
      views: topic.views,
    }));
  }
}
```

The exact endpoint and response shape depend on the feature and Discourse version.

## Why use `ajax()`

For normal Discourse frontend requests, the Discourse Ajax helper is preferable to scattering raw browser `fetch()` calls through theme code because it follows the frontend's request conventions and keeps the integration closer to existing Discourse code.

Raw `fetch()` is still technically possible for ordinary HTTP resources, but it should not be the default when the Discourse Ajax abstraction already fits the request.

## Common endpoint categories

Depending on the feature, existing Discourse JSON resources may expose:

```text
/latest.json
/top.json
/c/categories.json
/c/<category>.json
/t/<topic>.json
/t/<topic>/<post-number>.json
/u/<username>.json
/search.json?q=...
```

These are examples of endpoint patterns, not a guarantee that every route or response shape is identical in every Discourse version.

## Existing endpoint vs custom endpoint

Use an existing endpoint when it already contains the required information.

Create a custom backend endpoint when:

- the required data does not exist in an appropriate response,
- multiple backend sources need to be combined,
- the feature requires a purpose-built response shape,
- or the data must be exposed with feature-specific authorization rules.

---

# 9. Ember Data / Store

The Discourse frontend uses an Ember Data-style Store for model-backed data.

A GJS component can inject the Store and use the model/query patterns supported by the Discourse version.

```gjs
@service store;
```

Conceptually:

```js
const topic = await this.store.findRecord("topic", topicId);
```

or a collection/query pattern supported by the relevant Discourse model.

## When Store is appropriate

Use the Store when:

- the data is already modeled by Discourse,
- the frontend already uses that model,
- relationships or model semantics matter,
- or you need to work with existing Ember Data state rather than manually shaping an HTTP response.

## React boundary

Do not normally pass the model object directly into React.

```text
Store/model
    |
    | select fields / derive view data
    v
plain object / array
    |
    v
React
```

For example:

```js
const reactTopic = {
  id: topic.id,
  title: topic.title,
  slug: topic.slug,
  postsCount: topic.posts_count,
};
```

This prevents React from depending on Ember Data methods, observers, relationships, or model lifecycle behavior.

---

# 10. AppEvents and Reactive Synchronization

Some data is already available but can change while the React feature is mounted. In that case, the problem is not data acquisition; it is **synchronization**.

A common pattern is:

```text
Discourse state changes
        |
        v
App event / supported hook
        |
        v
GJS host re-reads or re-derives data
        |
        v
React receives updated props
```

Example concept:

```js
api.onAppEvent("topic-status-changed", () => {
  this.refreshReactData();
});
```

The event name and payload must come from the actual Discourse version/feature.

## Use this for

- navigation-driven changes
- user state changes
- topic state changes
- notifications
- application-level refresh events
- keeping an existing React island synchronized with Discourse state

## Avoid

Do not create a polling loop simply because the React feature needs fresh data if Discourse already exposes an event or tracked source that can drive the update.

---

# 11. Model Extensions and Transformers

Sometimes a React feature needs a field or derived value that is not naturally exposed by an existing model.

Discourse's extension mechanisms can add or transform model-level data before the GJS layer consumes it.

Conceptually:

```text
Discourse model
      |
      | extension / transformer
      v
extended data
      |
      v
GJS adapter
      |
      v
React
```

## Use this when

- the derived field is useful to multiple frontend consumers,
- the value belongs naturally to the model,
- or the feature requires integration with existing model serialization/behavior.

For a single small React widget, an adapter in the GJS layer is usually simpler than extending a core model.

Model extension is also more sensitive to Discourse upgrades than consuming an existing public surface.

---

# 12. Preloaded and Bootstrapped State

Discourse can make data available during application startup or page initialization. Some of this state is exposed through normal frontend objects and services.

Prefer consuming the **supported object/service that exposes the data** rather than parsing private bootstrap structures directly.

```text
Preferred:
preloaded state
      |
      v
Discourse service / Store / API
      |
      v
GJS

Avoid:
preloaded HTML / private JSON structure
      |
      v
manual parsing
```

Private bootstrap structures can change without providing a stable theme-facing contract.

---

# 13. Custom Backend Endpoint

If the existing frontend context, services, APIs, endpoints, and Store do not provide the required data, the clean solution may be a backend extension.

A plugin or core change can expose a purpose-built JSON endpoint:

```text
React feature requirement
        |
        v
GJS adapter
        |
        | ajax()
        v
Custom Rails route/controller
        |
        v
Application/domain data
```

A purpose-built response can be significantly cleaner than making React understand several unrelated Discourse endpoints.

Example response shape:

```json
{
  "items": [
    {
      "id": 123,
      "title": "Example topic",
      "status": "open"
    }
  ]
}
```

The endpoint should enforce the appropriate authorization on the server and return only the data required by the feature.

---

# 14. Core-Internal Access Mechanisms

A full Core checkout makes additional mechanisms technically available. These should be treated as **advanced/internal**, not the default integration strategy.

## 14.1 Direct core imports

A theme can sometimes import internal Discourse modules directly:

```js
import something from "discourse/...";
```

This can be useful when the required behavior is clearly part of the frontend implementation and there is no better theme-facing surface.

### Risk

Internal module paths, exports, and implementation contracts can change between Discourse upgrades.

If this is necessary, isolate it:

```text
React
  |
GJS adapter
  |
Internal Discourse module
```

Do not spread internal imports throughout React components.

## 14.2 Container lookup

Ember's application/container mechanisms can expose services or registered objects dynamically.

This is powerful but should generally be considered a fallback when normal injection or a documented API is not sufficient.

Prefer:

```gjs
@service store;
```

over dynamically reaching into the container for the same service.

## 14.3 DOM and `data-*` attributes

A React feature can technically read information already rendered into HTML:

```html
<div data-topic-id="123" data-category-id="7"></div>
```

This is useful when a boundary is explicitly represented in the DOM, but it should not be the primary application-data transport when a structured Discourse source is available.

Prefer:

```text
Discourse state -> GJS -> React
```

over:

```text
Discourse state -> rendered HTML -> DOM parsing -> React
```

## 14.4 Private bootstrap parsing

Parsing private global/preloaded structures directly belongs in the same last-resort category. If a supported service, Store, API, or endpoint exposes the information, use that instead.

---

# 15. REST Authentication and Security

Theme JavaScript runs in the browser. It should not contain privileged backend credentials.

For authenticated Discourse requests, use the normal authenticated browser session and the Discourse request mechanisms available to the frontend.

### Never put in theme/React code

```text
API secrets
private service credentials
admin tokens intended for server-to-server use
```

If a feature needs privileged information, move that operation to the server and expose only the authorized result to the browser.

## Data minimization

The GJS layer should pass only the fields React actually needs.

Instead of:

```js
componentProps={{ topic: fullTopicModel }}
```

prefer:

```js
componentProps={{
  topic: {
    id: topic.id,
    title: topic.title,
    slug: topic.slug,
  },
}}
```

This reduces coupling and makes the React contract easier to understand.

---

# 16. Avoiding Duplicate Data Fetches

Before adding an `ajax()` request, check whether the data already exists in:

1. outlet arguments,
2. component arguments,
3. route/page context,
4. a Discourse service,
5. the Store,
6. the JS API or existing application event,
7. an already-loaded model.

A common anti-pattern is:

```text
Discourse page already loaded topic
          |
          +--> React makes /t/123.json again
```

Prefer:

```text
Discourse page
    |
    v
GJS receives topic
    |
    | normalize
    v
React
```

If the page does not have the data, then an endpoint request is appropriate.

---

# 17. Recommended Adapter Structure

Keep Discourse-specific acquisition code near the GJS boundary.

A practical structure for the current project is:

```text
javascripts/discourse/
├── blocks/
│   └── block-react-counter.gjs
├── components/
│   └── ea-react-host.gjs
├── lib/
│   └── load-react-component.js
└── react-src/
    ├── bridge.tsx
    └── features/
        └── counter/
            ├── entry.tsx
            └── CounterWidget.tsx
```

The responsibilities should remain roughly:

```text
GJS connector
  - access Discourse
  - call services / APIs / ajax / Store
  - subscribe to supported events
  - normalize data

EaReactHost
  - mount bridge
  - pass explicit props
  - forward callbacks

React bridge
  - translate mount contract into React

React feature
  - render UI
  - manage feature-local state
  - call callbacks exposed by the host
```

---

# 18. Recommended Integration Patterns

## Pattern A — Data already exists on the page

```text
Outlet / parent component
        |
        v
GJS
        |
        v
EaReactHost
        |
        v
React
```

Use this whenever the current page already owns the data.

## Pattern B — Global frontend state

```text
Discourse service
        |
        v
GJS adapter
        |
        v
React
```

Typical examples: current user, site configuration, router state, notifications.

## Pattern C — Existing server JSON

```text
GJS
 |
 | ajax()
 v
Discourse endpoint
 |
 v
normalized props
 |
 v
React
```

Use this when the data is server-backed but not already available in the current component context.

## Pattern D — Store/model data

```text
GJS
 |
 v
Store/model
 |
 | select fields
 v
React
```

Use this when the data naturally belongs to an existing Discourse model.

## Pattern E — Event-driven refresh

```text
Discourse event
      |
      v
GJS refresh/derive
      |
      v
React props update
```

Use this when the feature needs to stay synchronized with changing Discourse state.

## Pattern F — Custom server data

```text
React requirement
      |
      v
GJS adapter
      |
      | ajax()
      v
Custom endpoint
      |
      v
React
```

Use this when no existing Discourse surface provides the required domain data.

---

# 19. Current Theme Architecture — Complete Example

The current project already follows the recommended bridge pattern.

## GJS host

A GJS block acquires data from Discourse and passes normalized props to `EaReactHost`.

```gjs
import Component from "@glimmer/component";
import { ajax } from "discourse/lib/ajax";

export default class ReactCounter extends Component {
  async loadTopics() {
    const data = await ajax("/latest.json");

    return (data.topic_list?.topics || []).map((topic) => ({
      id: topic.id,
      title: topic.title,
      slug: topic.slug,
      postsCount: topic.posts_count,
      views: topic.views,
    }));
  }
}
```

The host then passes the normalized result through `@componentProps`.

```gjs
<EaReactHost
  @componentProps={{hash
    posts=this.posts
  }}
/>
```

`EaReactHost` mounts the React bridge with the explicit contract:

```js
bridge.mount(element, {
  component,
  componentProps,
  currentUser,
});
```

## React bridge

The bridge translates the host contract into React props.

```tsx
root.render(
  <Component
    componentProps={componentProps}
    currentUser={currentUser}
  />
);
```

## React feature

The feature consumes the plain data contract:

```tsx
export function CounterWidget({ componentProps, currentUser }) {
  const posts = componentProps?.posts ?? [];

  return (
    <div>
      {posts.map((post) => (
        <div key={post.id}>{post.title}</div>
      ))}
    </div>
  );
}
```

The important part is not the specific endpoint. The important part is the boundary:

```text
Discourse data source
       |
       v
GJS acquisition
       |
       v
plain normalized contract
       |
       v
EaReactHost
       |
       v
React feature
```

---

# 20. Anti-Patterns

## React imports Discourse services directly

Avoid coupling React to Ember services:

```tsx
// Avoid
import { inject as service } from "@ember/service";
```

React should receive the required values from the GJS layer.

## React receives full Ember models

Avoid:

```js
componentProps={{ topic: emberTopic }}
```

Prefer:

```js
componentProps={{
  topic: {
    id: emberTopic.id,
    title: emberTopic.title,
  },
}}
```

## React independently fetches data already available to GJS

Avoid making child React components repeat the same Discourse request.

The GJS boundary should normally own the Discourse-specific acquisition logic.

## DOM scraping for structured data

Avoid querying arbitrary DOM text when the underlying application state is available through an API, service, model, or outlet argument.

## Private bootstrap parsing

Avoid parsing internal startup structures simply because they are visible in the browser.

## Excessive internal imports

One isolated adapter around a private API is easier to maintain than dozens of React components importing Discourse internals.

## Mixing configuration sources

Keep theme-owned settings in theme settings and site-wide application configuration in `siteSettings`.

---

# 21. Data-Source Decision Tree

Use the following decision tree when implementing a new React feature:

```text
START
  |
  v
Is the data already present in the current outlet/component?
  | yes
  v
Use outlet/component args
  |
  no
  v
Is it application state owned by a Discourse service?
  | yes
  v
Use the service in GJS
  |
  no
  v
Does the Theme/JS API provide the required value or hook?
  | yes
  v
Use the JS API
  |
  no
  v
Does an existing JSON endpoint provide it?
  | yes
  v
Use ajax() in the GJS/theme layer
  |
  no
  v
Is it represented by an Ember Data model?
  | yes
  v
Use the Store
  |
  no
  v
Can the data be exposed cleanly by a backend extension?
  | yes
  v
Create/use a custom endpoint
  |
  no
  v
Is a core-internal mechanism unavoidable?
  | yes
  v
Isolate it behind a small adapter
```

---

# 22. Integration Tiers

A practical stability model for this project is:

## Tier 1 — Context and theme-facing APIs

Prefer these first:

- outlet arguments
- component arguments
- route/page context
- cooked-content context
- Ember services
- theme settings
- `siteSettings`
- Theme/Plugin JS API

## Tier 2 — Existing application data sources

Use when Tier 1 does not provide the data:

- `ajax()` + existing JSON endpoint
- Store/model APIs
- supported application events

## Tier 3 — Extension mechanisms

Use when the feature requires deeper integration:

- model extensions
- transformers
- custom plugin/backend endpoint

## Tier 4 — Internal mechanisms

Use only when necessary:

- direct core imports
- container lookup
- private preloaded/bootstrap structures
- DOM/data attributes as a data transport

The lower the tier, the more deliberately the code should be isolated and tested against Discourse upgrades.

---

# 23. Practical Checklist

Before implementing a React data integration, answer these questions:

- Does the current outlet already provide the data?
- Does a parent GJS component already own it?
- Is the data available through a Discourse service?
- Is it theme configuration or a site setting?
- Does the Theme/Plugin JS API expose it?
- Is there an existing Discourse JSON endpoint?
- Is the data represented by the Store?
- Does the feature need live synchronization through an event?
- Would a custom endpoint provide a cleaner domain contract?
- Am I passing plain data into React rather than Ember objects?
- Am I fetching data twice that Discourse already loaded?
- If I use an internal API, is it isolated in one adapter?
- Does the server enforce authorization for sensitive data?

---

# 24. Recommended Rule for This Project

For the current EA Theme + React architecture, use this rule as the default:

> **Acquire Discourse data in GJS using the closest existing Discourse context, service, JS API, Store, or JSON endpoint. Normalize it at the React boundary, then pass only the required plain data into `EaReactHost` and React.**

In practice:

```text
                    ┌─────────────────────────┐
                    │   Discourse Core        │
                    │                         │
                    │ outlet / args           │
                    │ services                │
                    │ JS API                  │
                    │ Store                   │
                    │ JSON endpoints          │
                    │ backend extensions      │
                    └────────────┬────────────┘
                                 │
                                 v
                    ┌─────────────────────────┐
                    │   GJS Theme Layer       │
                    │                         │
                    │ acquire                 │
                    │ derive                  │
                    │ normalize               │
                    └────────────┬────────────┘
                                 │
                         plain React props
                                 │
                                 v
                    ┌─────────────────────────┐
                    │      EaReactHost        │
                    └────────────┬────────────┘
                                 │
                                 v
                    ┌─────────────────────────┐
                    │      React Feature      │
                    │                         │
                    │ UI + feature state      │
                    └─────────────────────────┘
```

This keeps the React layer portable and focused on UI/feature behavior while the GJS layer remains the controlled integration point with Discourse.
