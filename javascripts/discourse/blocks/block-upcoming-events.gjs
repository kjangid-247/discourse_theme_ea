import Component from "@glimmer/component";
import { trustHTML } from "@ember/template";
import { block } from "discourse/blocks";
// eslint-disable-next-line discourse/ui-kit-imports -- ui-kit paths not yet present in targeted Discourse (<= 2026.4); use stable path
import AsyncContent from "discourse/components/async-content";
import { ajax } from "discourse/lib/ajax";
import { bind } from "discourse/lib/decorators";
import { i18n } from "discourse-i18n";

@block("theme:ea-demo:upcoming-events", {
  description:
    "Upcoming events from discourse-calendar, as a sidebar list. Hides itself when there are none or the plugin is unavailable.",
  args: {
    heading: { type: "string" },
    count: { type: "number", default: 5 },
  },
})
export default class BlockUpcomingEvents extends Component {
  @bind
  async fetchData() {
    const count = this.args.count || 5;
    const data = await ajax("/discourse-post-event/events.json", {
      data: { limit: 50, include_details: true },
    });

    const now = Date.now();
    return (data.events || [])
      .map((event) => {
        const startsAt = event.starts_at ? new Date(event.starts_at) : null;
        return { event, startsAt };
      })
      .filter(({ startsAt }) => startsAt && startsAt.getTime() >= now)
      .sort((a, b) => a.startsAt - b.startsAt)
      .slice(0, count)
      .map(({ event, startsAt }) => ({
        id: event.id,
        title:
          event.post?.topic?.fancy_title ||
          event.name ||
          event.post?.topic?.title ||
          event.post?.title,
        url: event.post?.url,
        dateLabel: startsAt.toLocaleDateString(undefined, {
          month: "short",
          day: "numeric",
        }),
      }));
  }

  <template>
    <AsyncContent @asyncData={{this.fetchData}}>
      <:error></:error>
      <:content as |events|>
        {{#if events.length}}
          <section class="block-upcoming-events">
            {{#if @heading}}
              <h2 class="ea-section-heading">
                {{i18n (themePrefix @heading)}}
              </h2>
            {{/if}}

            <div class="ea-sidebar-card">
              <ul class="block-upcoming-events__list">
                {{#each events as |event|}}
                  <li class="block-upcoming-events__item">
                    <a href={{event.url}}>
                      <span class="block-upcoming-events__date">
                        {{event.dateLabel}}
                      </span>
                      <span class="block-upcoming-events__title">
                        {{trustHTML event.title}}
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
