import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { concat } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { trustHTML } from "@ember/template";
// eslint-disable-next-line discourse/ui-kit-imports -- ui-kit paths not yet present in targeted Discourse (<= 2026.4); use stable path
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class EaCategorySection extends Component {
  @tracked expanded = false;

  logoFor = (category) => {
    return category.uploaded_logo?.url || category.uploaded_logo_dark?.url;
  };

  initialFor = (category) => {
    return category.name?.charAt(0) || "?";
  };

  get initialCount() {
    return this.args.initialCount || this.args.categories.length;
  }

  get hasMore() {
    return this.args.categories.length > this.initialCount;
  }

  get visibleCategories() {
    if (this.expanded || !this.hasMore) {
      return this.args.categories;
    }
    return this.args.categories.slice(0, this.initialCount);
  }

  @action
  toggle() {
    this.expanded = !this.expanded;
  }

  <template>
    <section class="ea-category-section {{if @compact '--compact'}}">
      {{#if @title}}
        <h2 class="ea-category-section__title">{{@title}}</h2>
      {{/if}}

      <div class="ea-category-section__grid">
        {{#each this.visibleCategories as |category|}}
          <section class="category-card">
            <a class="category-card__main" href={{category.url}}>
              <div class="category-card__logo">
                {{#if (this.logoFor category)}}
                  <img src={{this.logoFor category}} alt={{category.name}} />
                {{else}}
                  <span
                    class="category-card__badge"
                    style={{trustHTML (concat "background:#" category.color)}}
                  >{{this.initialFor category}}</span>
                {{/if}}
              </div>
              <h3 class="category-card__title">{{category.name}}</h3>
            </a>
          </section>
        {{/each}}
      </div>

      {{#if this.hasMore}}
        <button type="button" class="ea-more-link" {{on "click" this.toggle}}>
          {{#if this.expanded}}
            {{i18n (themePrefix "homepage.categories.show_less")}}
            {{icon "chevron-up"}}
          {{else}}
            {{i18n (themePrefix "homepage.categories.show_all")}}
            {{icon "chevron-right"}}
          {{/if}}
        </button>
      {{/if}}
    </section>
  </template>
}
