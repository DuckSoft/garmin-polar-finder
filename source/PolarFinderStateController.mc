// Owns transient UI state shared by the view, renderer, and input handlers.
// Keeping this state in one object makes screen transitions explicit and keeps
// the WatchUi.View focused on lifecycle and event plumbing.
class PolarFinderStateController {
    var magnified = false;
    var screen = 0;
    var focus = 0;
    var scroll = 0;
    var rowTop = 116;
    var rowHalfHeight = 14;
    var editing = false;
    var helpPage = 0;
    
    function resetNavigation() {
        focus = 0;
        scroll = 0;
        rowHalfHeight = 0;
        magnified = false;
        editing = false;
    }
    
    function enter(nextScreen) {
        screen = nextScreen;
        resetNavigation();
    }
    
    function setFocus(nextFocus) {
        focus = nextFocus;
    }
}
