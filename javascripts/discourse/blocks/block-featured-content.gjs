import Component from "@glimmer/component";
import { trustHTML } from "@ember/template";
import { block } from "discourse/blocks";
// eslint-disable-next-line discourse/ui-kit-imports -- ui-kit paths not yet present in targeted Discourse (<= 2026.4); use stable path
import AsyncContent from "discourse/components/async-content";
import { ajax } from "discourse/lib/ajax";
import { bind } from "discourse/lib/decorators";
import { or } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

@block("theme:ea-demo:featured-content", {
  description:
    "Sidebar box listing topics that carry the configured featured tag",
})
export default class BlockFeaturedContent extends Component {
  get tag() {
    return settings.featured_tag;
  }

  @bind
  async loadTopics() {
    if (!this.tag) {
      return [];
    }

    const data = await ajax(`/tag/${this.tag}/l/latest.json`);

    const users = {};
    (data.users || []).forEach((u) => (users[u.id] = u));

    const max = settings.featured_content_max || 6;
    return (data.topic_list?.topics || []).slice(0, max).map((topic) => ({
      id: topic.id,
      title: topic.fancy_title || topic.title,
      href: `/t/${topic.slug}/${topic.id}`,
      author: users[topic.posters?.[0]?.user_id],
    }));
  }

  <template>
    <AsyncContent @asyncData={{this.loadTopics}}>
      <:content as |topics|>
        {{#if topics.length}}
          <section class="block-featured-content">
            <h2 class="ea-section-heading">
              {{i18n (themePrefix "homepage.featured_content.heading")}}
            </h2>
            <div class="ea-sidebar-card">
              <ul class="block-featured-content__list">
                {{#each topics as |topic|}}
                  <li class="block-featured-content__item">
                    <a class="block-featured-content__link" href={{topic.href}}>
                      <span class="block-featured-content__body">
                        <span class="block-featured-content__title">
                          {{trustHTML topic.title}}
                        </span>
                        {{#if topic.author}}
                          <span class="block-featured-content__author">
                            {{or topic.author.name topic.author.username}}
                          </span>
                        {{/if}}
                      </span>
                    </a>
                  </li>
                {{/each}}
              </ul>
            </div>
          </section>
        {{/if}}
      </:content>
    </AsyncContent>
  </template>
}
