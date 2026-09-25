// Rendering boundary for PolarFinderView. The view owns the screen-specific
// drawing primitives for now; this object owns dispatch so rendering can be
// moved screen-by-screen without changing the WatchUi lifecycle.
class PolarFinderRenderer {
    function render(view, dc) {
        view.renderScreen(dc);
    }
}
