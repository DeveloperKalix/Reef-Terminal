# Reef Media Trust & Safety Panel — Frontend entry point
#
# jac-client uses file-based routing from the pages/ directory.
# This file bootstraps the app and imports global styles.

cl {
    import "@styles/global.css";

    def:pub app(props: dict) -> JsxElement {
        return <div id="reef-panel-app">{props.children}</div>;
    }
}
