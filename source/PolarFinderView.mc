import Toybox.Graphics;
import Toybox.WatchUi;

class PolarFinderView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);

        var centerX = dc.getWidth() / 2;
        var centerY = dc.getHeight() / 2;
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawLine(centerX - 38, centerY + 8, centerX + 38, centerY + 8);
    }
}
