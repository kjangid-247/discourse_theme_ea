# Discourse Theme Architecture Decision Plan

## 1. Executive Summary

This document evaluates two architecture approaches for building our EA Discourse UI using:

- Discourse Themes
- Discourse Theme Components
- Ember/Glimmer
- React islands
- Paloma Design System
- GitHub-based development and CI
- Theme Creator / `discourse_theme watch`

### Preferred approach for our current use case

**Approach B — Complete Theme + Theme-Owned Internal Modules**

We recommend creating a new complete theme in its own Git repository and keeping its Navbar, Sidebar, Footer, React components, Paloma integrations, styles, and other feature modules inside that theme repository.

The key principle is:

> **Keep a feature inside the theme until there is a real, demonstrated requirement to reuse that feature across other themes. Extract it into a separate Discourse Theme Component only when cross-theme reuse becomes valuable.**

This gives us the simplest development and ownership model for a new complete theme while preserving a clean path to future reuse.

---

## 2. Decision Context

We already have an existing working Discourse theme, `ea_theme_v0`.

We are evaluating how to build a new/customized experience that may contain:

- custom Navbar
- custom Sidebar
- custom Footer
- custom homepage
- React-based interactive islands
- Paloma Design System components
- Ember/Glimmer Discourse integrations
- custom styling and responsive behavior

We also expect that some functionality may eventually need to be used by other Discourse themes, for example:

```text
theme_v3
    -> Sidebar only
```

The architectural question is therefore:

> Should reusable UI be developed as a shared Theme Component that can be attached to multiple themes, or should each complete theme own its internal UI modules until reuse is proven?

---

# 3. Discourse Concepts Relevant to the Decision

Discourse has two related but distinct concepts:

### Theme

A Theme is a complete frontend design/customization for a Discourse installation.

Discourse documentation describes themes as standalone designs; multiple themes can be installed, but only one theme is active for a given user/session at a time. citeturn267808search3

### Theme Component

A Theme Component is intended to customize a more focused aspect of Discourse and is designed to work alongside a parent theme and other components. Discourse supports installing a Theme Component from a Git repository and including it on one or more themes. citeturn267808search2turn267808search3

A repository is identified as a Theme Component rather than a complete theme using:

```json
{
  "component": true
}
```

in its `about.json`. citeturn267808search0

Discourse also supports remote Git repositories for themes/components, with updates available through the Discourse administration interface. citeturn267808search0turn267808search2

---

# 4. Approach A — Shared Theme Component Repository

## 4.1 Concept

Create one Git repository containing one Discourse Theme Component:

```text
GitHub
└── ea-shared-ui
    └── main
         |
         └── one Theme Component
                |
                ├── Navbar
                ├── Sidebar
                ├── Footer
                ├── React islands
                └── Paloma integration
```

This component can then be attached to multiple themes:

```text
                    ea-shared-ui
                         |
          +--------------+--------------+
          |              |              |
          v              v              v
     ea_theme_v0      theme_v3       theme_v4
```

Discourse supports adding a Theme Component to a theme through the theme's Included Components configuration, or selecting themes from the component's inclusion settings. citeturn267808search2

---

## 4.2 Example

`ea_theme_v0`:

```text
ea-shared-ui
    Navbar      = ON
    Sidebar     = ON
    Footer      = ON
    React       = ON
```

`theme_v3`:

```text
ea-shared-ui
    Navbar      = OFF
    Sidebar     = ON
    Footer      = OFF
    React       = OFF
```

This allows `theme_v3` to consume only the Sidebar functionality without copying the Sidebar implementation.

---

## 4.3 Internal structure

The repository would look conceptually like:

```text
ea-shared-ui/
├── about.json
├── settings.yml
├── javascripts/
│   └── discourse/
│       ├── api-initializers/
│       ├── components/
│       │   ├── ea-navbar.gjs
│       │   ├── ea-sidebar.gjs
│       │   └── ea-footer.gjs
│       └── react/
│           ├── GameSidebar/
│           ├── FeaturedHero/
│           └── CommunityCarousel/
├── stylesheets/
├── assets/
└── .github/
```

The repository is **one installable Theme Component**. The Navbar, Sidebar and Footer are internal modules; they are not separate independently installable components merely because they live in separate directories.

---

## 4.4 Advantages

### Strong cross-theme reuse

The same implementation can be attached to:

```text
ea_theme_v0
theme_v3
theme_v4
```

without copying source.

### Centralized maintenance

A fix to Sidebar is maintained in one repository.

### Consistent UI

Multiple themes can consume the same implementation and design-system integration.

### Clear shared platform model

This creates a reusable:

```text
EA Shared UI
```

layer above multiple Discourse themes.

### Good fit for proven shared functionality

This is especially useful when a feature is already known to be shared by several themes.

---

## 4.5 Disadvantages

### More coupling between unrelated features

Navbar, Sidebar and Footer now share the same deployment/versioning unit.

### Feature settings become important

A theme that needs only Sidebar must disable other features.

### Shared-component complexity

The component must remain theme-neutral because it can be attached to many different themes.

### More cross-theme testing

Every change may need validation against multiple consuming themes.

### Harder to optimize for one specific theme

A generic shared component cannot assume:

- a specific theme DOM structure
- a specific color system
- a specific page layout
- a specific header/sidebar implementation

---

# 5. Approach B — Complete Theme + Theme-Owned Internal Modules

## 5.1 Concept

Create a new complete theme in its own Git repository:

```text
GitHub
└── ea-theme-v1
    └── main
         |
         └── Complete Discourse Theme
               |
               ├── Navbar
               ├── Sidebar
               ├── Footer
               ├── React islands
               ├── Paloma integration
               ├── SCSS
               ├── assets
               └── theme-specific settings
```

Discourse treats the repository as a complete theme because it is not marked as a Theme Component.

The internal Navbar/Sidebar/Footer are ordinary theme-owned implementation modules.

---

## 5.2 Example repository

```text
ea-theme-v1/
├── about.json
├── settings.yml
├── common/
├── desktop/
├── mobile/
├── stylesheets/
│   ├── navbar.scss
│   ├── sidebar.scss
│   ├── footer.scss
│   └── theme.scss
├── javascripts/
│   └── discourse/
│       ├── api-initializers/
│       ├── components/
│       │   ├── ea-navbar.gjs
│       │   ├── ea-sidebar.gjs
│       │   ├── ea-footer.gjs
│       │   └── react-island-host.gjs
│       └── react/
│           ├── GameSidebar/
│           ├── FeaturedHero/
│           ├── FeatureGrid/
│           └── CommunityCarousel/
├── assets/
└── .github/
    └── copilot-instructions.md
```

---

## 5.3 Reuse behavior

These modules are **theme-owned**.

For example:

```text
ea-theme-v1
    └── Sidebar
```

does not become an independently installable Sidebar in:

```text
Admin → Themes & Components
```

A different theme cannot select it as a Theme Component because it is part of the `ea-theme-v1` repository rather than a separately packaged Theme Component.

This is intentional.

---

## 5.4 Advantages

### Simpler architecture

All UI belongs to one theme.

There is no requirement to design every module for arbitrary host themes.

### Strong visual consistency

Navbar, Sidebar, Footer and React modules can share:

- DOM assumptions
- CSS tokens
- layout structure
- theme settings
- design patterns
- Paloma integration

### Lower cross-theme complexity

The feature only needs to be validated against the target theme unless another consumer exists.

### Easier product development

Developers can evolve the complete theme as one coherent experience.

### Easier initial migration from an existing theme

If `ea_theme_v0` is used as the starting point, the team can copy/fork the existing theme and evolve it into `ea-theme-v1`.

Discourse supports themes from Git repositories and theme files can be maintained as a remote Git theme. citeturn267808search0turn267808search3

---

## 5.5 Disadvantages

### No immediate cross-theme reuse

If `theme_v3` later needs the same Sidebar, we cannot attach `ea-theme-v1`'s internal Sidebar through the Theme Component UI.

### Potential duplication if reuse appears later

A feature might initially exist in `ea-theme-v1` and later need to be extracted.

### Extraction work may be required later

The feature must be refactored to remove theme-specific assumptions before becoming a reusable Theme Component.

---

# 6. Direct Comparison

| Area | Approach A: Shared Theme Component | Approach B: Theme + Internal Modules |
|---|---|---|
| Git repositories | One shared component repo | One complete theme repo |
| Main branch | One | One |
| Discourse package | Theme Component | Complete Theme |
| Multiple consuming themes | Native and intended | Not directly |
| Feature reuse through Admin UI | Yes | No |
| Theme-specific optimization | Lower | Higher |
| Cross-theme compatibility burden | Higher | Lower |
| Initial implementation complexity | Higher | Lower |
| Shared feature maintenance | Centralized | Per-theme |
| Independent feature toggles | Recommended | Optional |
| Best for known shared UI | Yes | Not necessary |
| Best for one complete product/theme | Less direct | Yes |
| Ability to extract later | Possible | Possible |
| React + Glimmer | Supported | Supported |
| Paloma integration | Supported | Supported |

---

# 7. Important Architectural Clarification

A repository containing:

```text
Navbar
Sidebar
Footer
React components
```

does not automatically mean those are separate Discourse Theme Components.

### Shared-component model

```text
ea-shared-ui
     |
     └── ONE Theme Component
           ├── Navbar
           ├── Sidebar
           └── Footer
```

### Theme-owned model

```text
ea-theme-v1
     |
     └── ONE complete Theme
           ├── Navbar
           ├── Sidebar
           └── Footer
```

In both architectures the code can be modular.

The difference is **what Discourse treats as the installable/reusable boundary**.

---

# 8. Preferred Approach for Our Use Case

## Recommendation

**Start with Approach B: Complete Theme + Theme-Owned Internal Modules.**

Recommended initial repository:

```text
ea-theme-v1/
```

Use one Git repository and one `main` branch.

The theme can contain:

```text
Navbar
Sidebar
Footer
React islands
Paloma components
Glimmer components
theme-specific SCSS
theme-specific assets
theme-specific settings
```

### Why this is preferred initially

Our immediate objective is to build a **complete, coherent new EA Discourse experience**, not to build a generic UI platform for multiple unrelated themes.

The design shown for the target experience is highly integrated:

```text
Header
Sidebar
Featured content
Cards
Community navigation
Responsive layout
React interactions
```

These parts are likely to share:

- layout assumptions
- visual tokens
- spacing
- responsive breakpoints
- navigation structure
- page-level composition
- data contracts
- Paloma wrappers
- Discourse integration patterns

Keeping them together initially reduces architectural overhead.

---

# 9. Reuse Strategy Under the Preferred Approach

The preferred approach does **not** mean "never create Theme Components."

Instead, use **progressive extraction**.

### Phase 1 — Build inside the theme

```text
ea-theme-v1
├── Navbar
├── Sidebar
├── Footer
└── React modules
```

### Phase 2 — Another theme needs a feature

Example:

```text
theme_v3 needs Sidebar
```

At that point, determine whether Sidebar is truly reusable.

### Phase 3 — Extract the reusable feature

Create:

```text
ea-sidebar
```

as a separate Discourse Theme Component repository.

Then:

```text
ea-theme-v1
    └── consumes ea-sidebar

theme_v3
    └── consumes ea-sidebar
```

This follows Discourse's intended Theme Component model, where reusable focused customizations can be installed alongside themes. citeturn267808search3turn267808search2

---

# 10. Progressive Extraction Model

The recommended lifecycle is:

```text
              START
                |
                v
      Complete Theme
      ea-theme-v1
                |
       +--------+--------+
       |        |        |
       v        v        v
    Navbar   Sidebar   Footer
       |
       |  reuse proven?
       |
       v
Another theme requests Navbar
       |
       v
Assess reusability
       |
       v
Extract if justified
       |
       v
ea-navbar
Theme Component
       |
   +---+---+
   |       |
   v       v
v1      theme_v3
```

This avoids premature abstraction.

---

# 11. Decision Principle

Use this rule:

### Keep a feature inside the theme when:

- it is tightly coupled to the theme layout;
- it depends on the theme's DOM structure;
- it shares theme-specific visual assumptions;
- it is currently used by one theme;
- its API is still changing;
- there is no confirmed second consumer.

### Extract into a Theme Component when:

- a second theme genuinely needs it;
- the feature has a stable interface;
- theme-specific assumptions can be removed;
- independent maintenance is valuable;
- cross-theme compatibility is understood;
- the feature has clear ownership and lifecycle.

---

# 12. Example: Sidebar

### Today

```text
ea-theme-v1
└── Sidebar
```

No separate component repository.

### Later

`theme_v3` needs the exact Sidebar.

We evaluate:

```text
Is Sidebar theme-neutral?
Does it rely on v1-specific DOM?
Does it use theme-specific CSS?
Can Paloma/Glimmer boundaries be generalized?
Is the feature API stable?
```

If yes:

```text
ea-sidebar
```

becomes a Theme Component.

Then:

```text
ea-theme-v1
    + ea-sidebar

theme_v3
    + ea-sidebar
```

If no, keep separate implementations.

---

# 13. React Architecture Under Both Approaches

The React strategy remains the same.

React is always an isolated island.

```text
Discourse
   |
Glimmer
   |
React Host
   |
React Island
   |
Paloma
```

React should not replace:

- Discourse routing
- authentication
- permissions
- Composer
- moderation
- core topic/post rendering

The difference between the two approaches is only **where the React-containing feature is packaged**:

### Approach A

```text
ea-shared-ui
   └── React feature
```

### Approach B

```text
ea-theme-v1
   └── React feature
```

---

# 14. Paloma Strategy

Paloma remains the preferred design system in both approaches.

Before creating a custom primitive:

1. inspect the Paloma Storybook;
2. search the repository for existing Paloma usage;
3. inspect package/type definitions when available;
4. reuse the existing component/token if suitable;
5. build a local wrapper only when necessary.

Do not invent Paloma component names, props, tokens or imports.

Reference:

https://eait-plex-xo-design-storybook.itcloud.ea.com/main/storybook/index.html?path=/docs/getting-started--documentation

---

# 15. Discourse Development Strategy

Regardless of the selected architecture:

### Ember/Glimmer

Use modern `.gjs` components and current Discourse APIs.

### Plugin Outlets

Prefer supported outlets and API initializers for Discourse integration.

### React

Keep React mounted through an explicitly owned Glimmer lifecycle boundary.

### Git

Keep GitHub as the source of truth.

### Theme Creator

Use Theme Creator for preview/rapid iteration.

### Local Discourse

Use a local Discourse environment where practical for complex integration/lifecycle debugging.

Discourse documents the Theme CLI and Theme Creator as development tooling for themes and components. citeturn267808search4

---

# 16. Repository and CI Strategy

## Preferred repository

```text
ea-theme-v1
```

One:

```text
main
```

branch as the canonical branch.

GitHub Actions validates:

- theme structure
- JavaScript/GJS
- React build where applicable
- settings
- lint/tests
- browser/integration checks where configured

The exact build strategy should follow the actual repository rather than introducing an unnecessary second application toolchain.

---

# 17. Migration from `ea_theme_v0`

There are two practical starting points.

### Option 1 — Create from scratch

Use when:

- v0 architecture is unsuitable;
- the visual system is changing significantly;
- there is little code to reuse.

### Option 2 — Start from an existing v0 ZIP/repository

Use when:

- v0 already contains useful Discourse integration;
- existing settings are valuable;
- existing SCSS/layout can be reused;
- the new theme is an evolution rather than a fundamentally unrelated product.

The copied/forked code becomes the initial state of `ea-theme-v1`.

After that, `ea-theme-v1` should have its own Git history/source-of-truth unless the team deliberately maintains v0 as an upstream source.

---

# 18. Stakeholder Decision Questions

Before implementation, stakeholders should decide:

### Question 1
Is the immediate goal a **complete new theme** or a **shared UI platform**?

- Complete new theme → Approach B
- Shared UI platform → Approach A

### Question 2
Do we already have multiple confirmed consuming themes for the same feature?

- Yes → Approach A has a stronger case
- No → Approach B is simpler

### Question 3
Do we expect Navbar/Sidebar/Footer to remain theme-specific?

- Yes → Approach B
- No, they are product-wide shared UI → Approach A

### Question 4
Do we want independent reuse through:

```text
Admin → Themes & Components
```

from day one?

- Yes → build those features as Theme Components
- No → keep them theme-owned

---

# 19. Recommended Decision

## Adopt Approach B initially

```text
GitHub
└── ea-theme-v1
    └── main
         |
         └── Complete Discourse Theme
              |
              ├── Ember/Glimmer
              ├── React islands
              ├── Paloma
              ├── Navbar
              ├── Sidebar
              ├── Footer
              └── theme-specific UI
```

### With a deliberate future extraction path:

```text
ea-theme-v1
     |
     | proven reusable feature
     v
Theme Component repository
     |
     +--> ea-sidebar
     +--> ea-navbar
     +--> ea-featured-content
```

This gives us:

- lower initial complexity;
- stronger theme cohesion;
- simpler development;
- fewer cross-theme compatibility constraints;
- freedom to evolve the design quickly;
- no premature abstraction;
- a clear path to reuse when reuse is actually required.

---

# 20. Risks and Mitigations

| Risk | Approach B Mitigation |
|---|---|
| Feature later needed by another theme | Extract it into a Theme Component |
| Duplicate implementations | Extract only after reuse is proven |
| Theme becomes too large | Modularize internally |
| React complexity grows | Keep strict React-island boundary |
| Discourse API changes | Isolate Discourse integration in Glimmer |
| Paloma API changes | Keep Paloma usage behind clear UI boundaries |
| Theme-specific CSS conflicts | Scope selectors |
| Maintenance burden | Keep feature modules independent |
| Cross-theme reuse becomes common | Introduce shared Theme Components progressively |

---

# 21. Final Architecture

The recommended near-term architecture is:

```text
                           GitHub
                             |
                        ea-theme-v1
                           main
                             |
               +-------------+-------------+
               |             |             |
           Discourse       React        Paloma
           Glimmer        islands       Design
               |             |             |
               +-------------+-------------+
                             |
                    Complete EA Theme
                             |
          +------------------+------------------+
          |                  |                  |
       Navbar             Sidebar             Footer
          |                  |                  |
          +------------------+------------------+
                             |
                     theme-specific UX
```

Later, proven reusable features can move outside:

```text
                    GitHub
                      |
          +-----------+------------+
          |                        |
     ea-theme-v1              ea-sidebar
          |                        |
          |                 Theme Component
          |                        |
          |              +---------+---------+
          |              |                   |
          +--------------+                theme_v3
                         |
                     reusable UI
```

---

# 22. Decision Record

**Proposed decision:** Approach B — Complete Theme + Theme-Owned Internal Modules.

**Initial repository:** `ea-theme-v1`

**Repository model:** One Git repository, one canonical `main` branch.

**Frontend model:** Discourse + Ember/Glimmer + isolated React islands.

**Design system:** Paloma wherever an appropriate component/token/pattern exists.

**Reuse policy:** Keep features internal initially; extract proven cross-theme features into separate Discourse Theme Component repositories.

**Review point:** Revisit the architecture when a second theme requests the same feature or when independent feature ownership/versioning becomes necessary.

---

# 23. References

Discourse — Structure of themes and theme components:
https://meta.discourse.org/t/structure-of-themes-and-theme-components/60848

Discourse — Installing a theme or theme component:
https://meta.discourse.org/t/installing-a-theme-or-theme-component/63682

Discourse — Theme Developer Tutorial: Introduction:
https://meta.discourse.org/t/theme-developer-tutorial-1-introduction/357796

Discourse — Developing Discourse Themes & Theme Components:
https://meta.discourse.org/t/developing-discourse-themes-theme-components/93648

Discourse — Theme Creator / Theme CLI:
https://meta.discourse.org/t/get-started-with-theme-creator-and-the-theme-cli/108444

EA Paloma Storybook:
https://eait-plex-xo-design-storybook.itcloud.ea.com/main/storybook/index.html?path=/docs/getting-started--documentation
