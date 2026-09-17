import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { concat, fn } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { block } from "discourse/blocks";
// eslint-disable-next-line discourse/ui-kit-imports -- ui-kit paths not yet present in targeted Discourse (<= 2026.4); use stable path
import AsyncContent from "discourse/components/async-content";
import BasicTopicList from "discourse/components/basic-topic-list";
import { bind } from "discourse/lib/decorators";
import { eq } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

const TABS = [
  { id: "newest", filter: "latest", params: { order: "created" } },
  { id: "likes", filter: "latest", params: { order: "likes" } },
  { id: "views", filter: "latest", params: { order: "views" } },
  { id: "replies", filter: "latest", params: { order: "posts" } },
];

@block("theme:ea-demo:topic-list", {
  description:
    "Tabbed topic list backed by a core topic list (so Topic Cards applies)",
})
export default class BlockTopicList extends Component {
  @service store;

  @tracked activeTab = "newest";

  tabs = TABS;

  @action
  setTab(id) {
    this.activeTab = id;
  }

  @bind
  async loadList(tab) {
    const config = TABS.find((t) => t.id === tab) || TABS[0];
    return this.store.findFiltered("topicList", {
      filter: config.filter,
      params: config.params,
    });
  }

  <template>
    <div class="block-topic-list">
      <nav class="block-topic-list__tabs">
        {{#each this.tabs as |tab|}}
          <button
            type="button"
            class="block-topic-list__tab
              {{if (eq tab.id this.activeTab) '--active'}}"
            {{on "click" (fn this.setTab tab.id)}}
          >
            {{i18n (themePrefix (concat "homepage.topics.tabs." tab.id))}}
          </button>
        {{/each}}
      </nav>

      <AsyncContent @asyncData={{this.loadList}} @context={{this.activeTab}}>
        <:content as |topicList|>
          <BasicTopicList @topicList={{topicList}} />
        </:content>
      </AsyncContent>
    </div>
  </template>
}
