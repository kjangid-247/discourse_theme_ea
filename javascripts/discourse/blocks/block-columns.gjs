import Component from "@glimmer/component";
import { block } from "discourse/blocks";

@block("theme:ea-demo:columns", {
  description: "Lays children out in a main + aside two-column row",
  container: true,
  childArgs: {
    span: { type: "string", enum: ["main", "aside"], default: "main" },
  },
})
export default class BlockColumns extends Component {
  <template>
    <div class="block-columns">
      {{#each @children key="key" as |child|}}
        <div class="block-columns__cell --{{child.containerArgs.span}}">
          <child.Component />
        </div>
      {{/each}}
    </div>
  </template>
}
