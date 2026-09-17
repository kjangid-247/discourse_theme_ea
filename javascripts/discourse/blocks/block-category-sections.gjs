import Component from "@glimmer/component";
import { service } from "@ember/service";
import { block } from "discourse/blocks";
import EaCategorySection from "../components/ea-category-section";

@block("theme:ea-demo:category-sections", {
  description:
    "Stacked, configurable category sections — each with a title, featured categories, and a Show all toggle",
  args: {
    offset: { type: "number", default: 0 },
    limit: { type: "number" },
  },
})
export default class BlockCategorySections extends Component {
  @service site;

  get sections() {
    const config = settings.category_sections || [];
    const all = config
      .map((section) => ({
        title: section.title,
        initialCount: section.initial_count || 0,
        compact: section.compact || false,
        categories: this.resolveCategories(section.categories),
      }))
      .filter((section) => section.categories.length > 0);

    const offset = this.args.offset || 0;
    return this.args.limit != null
      ? all.slice(offset, offset + this.args.limit)
      : all.slice(offset);
  }

  resolveCategories(value) {
    if (!value) {
      return [];
    }
    const items = Array.isArray(value) ? value : String(value).split("|");
    const ids = items
      .map((v) => (typeof v === "object" ? v?.id : parseInt(v, 10)))
      .filter((id) => id != null && !isNaN(id));
    return ids
      .map((id) => (this.site.categories || []).find((c) => c.id === id))
      .filter(Boolean);
  }

  <template>
    <div class="block-category-sections">
      {{#each this.sections as |section|}}
        <EaCategorySection
          @title={{section.title}}
          @categories={{section.categories}}
          @initialCount={{section.initialCount}}
          @compact={{section.compact}}
        />
      {{/each}}
    </div>
  </template>
}
