import Toybox.Application;
import Toybox.Lang;
import Toybox.Position;
import Toybox.WatchUi;

class PolarFinderApp extends Application.AppBase {
    private var _view;
    private var _delegate;
    
    function initialize() {
        AppBase.initialize();
    }
    
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var model = new PolarFinderModel();
        _view = new PolarFinderView(model);
        _delegate = new PolarFinderDelegate(_view);
        return [_view, _delegate];
    }
    
    function startGps() {
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }
    
    function stopGps() {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
    }
    
    function onPosition(info as Position.Info) as Void {
        if (_view != null) {
            _view.onPosition(info);
        }
    }
    
    function onStop(state) {
        stopGps();
        if (_view != null) {
            _view.stopTimers();
        }
    }
    
    function onInactive(state) {
        if (_view != null) {
            _view.onAppInactive();
        }
    }
    
    function onActive(state) {
        if (_view != null) {
            _view.onAppActive();
        }
    }
}

function getApp() {
    return Application.getApp() as PolarFinderApp;
}
