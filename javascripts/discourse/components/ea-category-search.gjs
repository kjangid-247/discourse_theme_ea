import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
// eslint-disable-next-line discourse/ui-kit-imports -- ui-kit paths not yet present in targeted Discourse (<= 2026.4); use stable path
import icon from "discourse/helpers/d-icon";
import DiscourseURL from "discourse/lib/url";
import { i18n } from "discourse-i18n";

export default class EaCategorySearch extends Component {
  @service discovery;

  @tracked term = "";

  get category() {
    return this.discovery.category;
  }

  get placeholder() {
    return i18n(themePrefix("category_search.placeholder"), {
      category: this.category?.name,
    });
  }

  @action
  updateTerm(event) {
    this.term = event.target.value;
  }

  @action
  search(event) {
    event.preventDefault();
    const category = this.category;
    if (!category) {
      return;
    }
    const query = `${this.term} #${category.slug}`.trim();
    DiscourseURL.routeTo(`/search?q=${encodeURIComponent(query)}`);
  }

  <template>
    {{#if this.category}}
      <form class="ea-category-search" {{on "submit" this.search}}>
        <label class="ea-category-search__field">
          {{icon "magnifying-glass"}}
          <input
            type="search"
            class="ea-category-search__input"
            placeholder={{this.placeholder}}
            value={{this.term}}
            aria-label={{this.placeholder}}
            {{on "input" this.updateTerm}}
          />
        </label>
      </form>
    {{/if}}
  </template>
}
