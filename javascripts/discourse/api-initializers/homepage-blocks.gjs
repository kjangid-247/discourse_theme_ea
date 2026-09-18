import { apiInitializer } from "discourse/lib/api";
import BlockAbout from "../blocks/block-about";
import BlockCategorySections from "../blocks/block-category-sections";
import BlockColumns from "../blocks/block-columns";
import BlockFeaturedContent from "../blocks/block-featured-content";
import BlockLeaderboard from "../blocks/block-leaderboard";
import BlockReactCounter from "../blocks/block-react-counter";
import BlockStack from "../blocks/block-stack";
import BlockTopicList from "../blocks/block-topic-list";
import BlockUpcomingEvents from "../blocks/block-upcoming-events";

export default apiInitializer((api) => {
  api.renderBlocks("homepage-blocks", [
    {
      block: BlockReactCounter,
      id: "ea-react-counter",
    },
    {
      block: BlockCategorySections,
      id: "ea-category-first",
      args: { limit: 1 },
    },
    {
      block: BlockColumns,
      id: "ea-category-row",
      children: [
        {
          block: BlockCategorySections,
          id: "ea-category-rest",
          args: { offset: 1 },
          containerArgs: { span: "main" },
        },
        {
          block: BlockLeaderboard,
          id: "ea-leaderboard",
          containerArgs: { span: "aside" },
          args: {
            heading: "homepage.leaderboard.heading",
            seeAllLabel: "homepage.leaderboard.see_all",
            count: 10,
          },
        },
      ],
    },
    {
      block: BlockColumns,
      id: "ea-discovery",
      children: [
        {
          block: BlockTopicList,
          id: "ea-topic-list",
          containerArgs: { span: "main" },
        },
        {
          block: BlockStack,
          id: "ea-sidebar",
          containerArgs: { span: "aside" },
          children: [
            { block: BlockFeaturedContent, id: "ea-featured-content" },
            {
              block: BlockUpcomingEvents,
              id: "ea-upcoming-events",
              args: { heading: "homepage.events.heading", count: 5 },
            },
            { block: BlockAbout, id: "ea-about" },
          ],
        },
      ],
    },
  ]);
});
