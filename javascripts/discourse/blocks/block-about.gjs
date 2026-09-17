import Component from "@glimmer/component";
import { block } from "discourse/blocks";

@block("theme:ea-demo:about", {
  description:
    "Sidebar box with an about heading and description from settings",
})
export default class BlockAbout extends Component {
  get title() {
    return settings.about_title;
  }

  get text() {
    return settings.about_text;
  }

  <template>
    {{#if this.text}}
      <section class="block-about">
        {{#if this.title}}
          <h2 class="ea-section-heading">{{this.title}}</h2>
        {{/if}}
        <div class="ea-sidebar-card">
          <p class="block-about__text">{{this.text}}</p>
        </div>
      </section>
    {{/if}}
  </template>
}
