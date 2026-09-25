// Calculation lifecycle boundary. The numerical pipeline remains in the view
// during this incremental refactor, while this service owns the public start
// and stop seam used by lifecycle and input code.
class PolarFinderCalculationService {
    private var _active = false;
    
    function begin(view, restarting) {
        _active = true;
        view.beginCalculationImpl(restarting);
    }
    
    function stop(view) {
        if (_active) {
            _active = false;
            view.cancelCalculationFromService();
        }
    }
    
    function completed() {
        _active = false;
    }
    
    function isActive() {
        return _active;
    }
}
