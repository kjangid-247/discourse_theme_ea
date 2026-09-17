import Component from "@glimmer/component";
import { service } from "@ember/service";
import { block } from "discourse/blocks";
// eslint-disable-next-line discourse/ui-kit-imports -- ui-kit paths not yet present in targeted Discourse (<= 2026.4); use stable path
import AsyncContent from "discourse/components/async-content";
// eslint-disable-next-line discourse/ui-kit-imports -- ui-kit paths not yet present in targeted Discourse (<= 2026.4); use stable path
import icon from "discourse/helpers/d-icon";
import { ajax } from "discourse/lib/ajax";
import { avatarUrl } from "discourse/lib/avatar-utils";
import { bind } from "discourse/lib/decorators";
import { i18n } from "discourse-i18n";

@block("theme:ea-demo:leaderboard", {
  description:
    "Top members from the gamification leaderboard, as ranked rows. Hides itself when gamification is unavailable.",
  args: {
    heading: { type: "string" },
    seeAllLabel: { type: "string" },
    count: { type: "number", default: 10 },
    leaderboardId: { type: "number" },
  },
})
export default class BlockLeaderboard extends Component {
  @service siteSettings;

  get seeAllUrl() {
    return this.args.leaderboardId
      ? `/leaderboard/${this.args.leaderboardId}`
      : "/leaderboard";
  }

  @bind
  async fetchData() {
    const count = this.args.count || 10;
    const data = await ajax(this.seeAllUrl, { data: { user_limit: count } });

    return (data.users || []).slice(0, count).map((user, index) => ({
      ...user,
      rank: index + 1,
      isWinner: index === 0,
      avatar: avatarUrl(user.avatar_template, "small"),
      displayName: this.siteSettings.prioritize_username_in_ux
        ? user.username
        : user.name || user.username,
    }));
  }

  <template>
    <AsyncContent @asyncData={{this.fetchData}}>
      <:error></:error>
      <:content as |users|>
        {{#if users.length}}
          <section class="block-leaderboard">
            {{#if @heading}}
              <h2 class="block-leaderboard__heading">
                {{i18n (themePrefix @heading)}}
              </h2>
            {{/if}}

            <div class="block-leaderboard__card">
              <ol class="block-leaderboard__list">
                {{#each users as |user|}}
                  <li class="block-leaderboard__item">
                    <span
                      class="block-leaderboard__rank
                        {{if user.isWinner '--winner'}}"
                    >
                      {{#if user.isWinner}}
                        {{icon "crown"}}
                      {{else}}
                        {{user.rank}}
                      {{/if}}
                    </span>
                    <a
                      class="block-leaderboard__user"
                      href="/u/{{user.username}}"
                      data-user-card={{user.username}}
                    >
                      {{#if user.avatar}}
                        <img
                          class="block-leaderboard__avatar"
                          src={{user.avatar}}
                          alt={{user.displayName}}
                          width="24"
                          height="24"
                        />
                      {{/if}}
                      <span class="block-leaderboard__name">
                        {{user.displayName}}
                      </span>
                    </a>
                    <span class="block-leaderboard__score">
                      {{user.total_score}}
                    </span>
                  </li>
                {{/each}}
              </ol>
            </div>

            {{#if @seeAllLabel}}
              <a href={{this.seeAllUrl}} class="ea-more-link">
                {{i18n (themePrefix @seeAllLabel)}}
                {{icon "chevron-right"}}
              </a>
            {{/if}}
          </section>
        {{/if}}
      </:content>
    </AsyncContent>
  </template>
}
