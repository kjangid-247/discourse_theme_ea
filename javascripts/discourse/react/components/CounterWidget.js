// AUTO-GENERATED from react-src/*.jsx via `npm run build:react` — do not edit directly.
// Counter widget using Paloma primitives through the shared lazy-loaded bundle.
export default function createCounterWidget(React, Paloma) {
  return function CounterWidget() {
    const [count, setCount] = React.useState(0);
    const [activeSlide, setActiveSlide] = React.useState(0);
    const {
      ThemeProvider,
      Button,
      Badge,
      Carousel
    } = Paloma;
    return /*#__PURE__*/React.createElement("div", {
      className: "ea-paloma-scope"
    }, /*#__PURE__*/React.createElement(ThemeProvider, {
      theme: "ea-blue",
      mode: "dark"
    }, /*#__PURE__*/React.createElement("div", {
      className: "ea-counter-widget"
    }, /*#__PURE__*/React.createElement(Badge, {
      label: "New"
    }), /*#__PURE__*/React.createElement("p", {
      className: "ea-counter-widget__value"
    }, "Count: ", count), /*#__PURE__*/React.createElement(Button, {
      variant: "primary",
      onPress: () => setCount(current => current + 1)
    }, "Increment for counter"), /*#__PURE__*/React.createElement(Carousel, {
      className: "ea-counter-widget__carousel",
      arrows: true,
      dots: true,
      onSlideChange: setActiveSlide,
      withBackdropBlur: true
    }, /*#__PURE__*/React.createElement("div", {
      className: "ea-counter-widget__slide"
    }, /*#__PURE__*/React.createElement("strong", null, "Interactive counter"), /*#__PURE__*/React.createElement("span", null, "Current value: ", count)), /*#__PURE__*/React.createElement("div", {
      className: "ea-counter-widget__slide"
    }, /*#__PURE__*/React.createElement("strong", null, "Active slide"), /*#__PURE__*/React.createElement("span", null, "Slide ", activeSlide + 1, " of 2"))))));
  };
}
