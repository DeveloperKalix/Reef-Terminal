# Protected route group layout.
# Renders children via Outlet — no auth guard here.
# Auth checks are handled in individual pages.

cl import from "@jac/runtime" { Outlet }

cl {
    def:pub layout() -> JsxElement {
        return <Outlet />;
    }
}
