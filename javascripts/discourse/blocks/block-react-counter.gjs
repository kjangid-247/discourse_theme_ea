import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { block } from "discourse/blocks";
import { ajax } from "discourse/lib/ajax";
import EaReactHost from "../components/ea-react-host";
import { service } from "@ember/service";

@block("theme:ea-demo:react-counter", {
  description: "React counter demonstration",
})
export default class BlockReactCounter extends Component {
  @service currentUser;

  @tracked posts = [];
  @tracked postsLoaded = false;

  constructor(...args) {
    super(...args);
    this.loadPosts();
  }

  async loadPosts() {
    try {
      const data = await ajax("/latest.json");

      this.posts = (data.topic_list?.topics || []).map((topic) => ({
        id: topic.id,
        title: topic.fancy_title || topic.title,
        slug: topic.slug,
        postsCount: topic.posts_count,
        views: topic.views,
      }));
    } catch (error) {
      console.error("Unable to load the latest posts.", error);
    } finally {
      this.postsLoaded = true;
    }
  }
  

  <template>
    <section class="block-shared-components-example">
      {{#if this.postsLoaded}}
        <EaReactHost
          @component="counter"
          @componentProps={{hash
            initialCount=3
            posts=this.posts
          }}
          @currentUser={{this.currentUser}}
          @feature="counter"
        />
      {{/if}}
    </section>
  </template>
}