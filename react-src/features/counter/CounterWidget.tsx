import { useEffect, useState } from "react";
import type { ReactBridgeProps } from "../../bridge";
import getSharedComponents from "../../shared_components/adapter";
import { getDiscourseColorMode, subscribeToDiscourseColorMode } from "../../utils";

export default function CounterWidget({ componentProps, currentUser }: ReactBridgeProps) {
  const initialCount = Number(componentProps?.initialCount ?? 0);
  const posts = componentProps?.posts ?? [];
  const [count, setCount] = useState(initialCount);
  const { Button, ThemeProvider, Carousel } = getSharedComponents();
  const [mode, setMode] = useState(getDiscourseColorMode);

  useEffect(() => {
    console.log("currentUser:", currentUser);
    console.log("posts:", posts);
  }, [currentUser, posts]);

  useEffect(() => subscribeToDiscourseColorMode(setMode), []);

  function increment() {
    setCount(count + 1);
  }

  return (
    <div className="ea-shared-components-scope">
      <ThemeProvider theme="ea-blue" mode={mode}>
        <section className="ea-shared-components-example" aria-labelledby="ea-react-counter-title">
          <h2 id="ea-react-counter-title" className="ea-shared-components-example__title">
            React counter
          </h2>
          <p className="ea-shared-components-example__message">Current count: {count}</p>
          <Button onPress={increment}>Increment</Button>

          <Carousel
            title="Carousel Title"
            titleTag="div"
            arrows
            dots
            className="ea-shared-components-carousel"
            carouselItemWrapperClassname="ea-shared-components-carousel__slide"
            overlap={12}
            scale={0.9}
            withBackdropBlur
            forwardArrowLabel="Forward"
            backArrowLabel="Back"
          >
            <article className="ea-shared-components-carousel__card">
              <h3>Example 1</h3>
              <ul>
                <li>Item 1</li>
                <li>Item 2</li>
                <li>Item 345</li>
              </ul>
            </article>
            <article className="ea-shared-components-carousel__card">
              <h3>Example 2</h3>
              <ul>
                <li>Item 1</li>
                <li>Item 2</li>
                <li>Item 3</li>
              </ul>
            </article>
            <article className="ea-shared-components-carousel__card">
              <h3>Example 3</h3>
              <ul>
                <li>Item 1</li>
                <li>Item 2</li>
                <li>Item 3</li>
              </ul>
            </article>
          </Carousel>
        </section>
      </ThemeProvider>
    </div>
  );
}