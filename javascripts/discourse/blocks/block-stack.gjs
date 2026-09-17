import Component from "@glimmer/component";
import { block } from "discourse/blocks";

@block("theme:ea-demo:stack", {
  description: "Stacks children vertically with consistent spacing",
  container: true,
})
export default class BlockStack extends Component {
  <template>
    <div class="block-stack">
      {{#each @children key="key" as |child|}}
        <child.Component />
      {{/each}}
    </div>
  </template>
}
