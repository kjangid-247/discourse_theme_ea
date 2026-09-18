import Component from "@glimmer/component";
import { block } from "discourse/blocks";
import EaReactHost from "../components/ea-react-host";

@block("theme:ea-demo:react-counter", {
  description: "React counter demonstration",
})
export default class BlockReactCounter extends Component {
  <template>
    <section class="block-react-example">
      <EaReactHost
        @component="counter"
        @componentProps={{hash initialCount=3}}
        @feature="counter"
      />
    </section>
  </template>
}