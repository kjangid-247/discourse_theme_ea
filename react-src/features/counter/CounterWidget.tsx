import { useEffect, useState } from "react";
import type { ReactBridgeProps } from "../../bridge";
import getPaloma from "../../paloma/adapter";
import { getDiscourseColorMode, subscribeToDiscourseColorMode } from "../../utils";

export default function CounterWidget({ componentProps }: ReactBridgeProps) {
  const initialCount = Number(componentProps?.initialCount ?? 0);
  const [count, setCount] = useState(initialCount);
  const { Button, ThemeProvider ,Carousel} = getPaloma();
  const [mode, setMode] = useState(getDiscourseColorMode);

  useEffect(() => subscribeToDiscourseColorMode(setMode), []);

  function increment() {
    setCount(count + 1);
  }

  return (
    <div className="ea-paloma-scope">
      <ThemeProvider theme="ea-blue" mode={mode}>
        <section className="ea-react-example" aria-labelledby="ea-react-counter-title">
          <h2 id="ea-react-counter-title" className="ea-react-example__title">
            React counter : kalpit jangid zz
          </h2>
          <p className="ea-react-example__message">Current count: {count}</p>
          <Button onPress={increment}>Increment</Button>

          <Carousel
            title="Carousel Title"
            titleTag="div"
            arrows
            dots
            className="ea-paloma-carousel"
            carouselItemWrapperClassname="ea-paloma-carousel__slide"
            overlap={12}
            scale={0.9}
            withBackdropBlur
            forwardArrowLabel="Forward"
            backArrowLabel="Back"
          >
            <article className="ea-paloma-carousel__card">
              <h3>Example 1</h3>
              <ul>
                <li>Item 1</li>
                <li>Item 2</li>
                <li>Item 3</li>
              </ul>
            </article>
            <article className="ea-paloma-carousel__card">
              <h3>Example 2</h3>
              <ul>
                <li>Item 1</li>
                <li>Item 2</li>
                <li>Item 3</li>
              </ul>
            </article>
            <article className="ea-paloma-carousel__card">
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