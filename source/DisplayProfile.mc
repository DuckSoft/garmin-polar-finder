class DisplayProfile {
    var width;
    var height;
    var centerX;
    var centerY;
    var titleY;
    var footerY;
    var drawableTop;
    var drawableBottom;
    var rowPitch;
    var rowLeft;
    var rowRight;
    var labelX;
    var valueX;
    var contentWidth;
    var detailWidth;
    var reticleRadius;
    var reticleSafeRadius;
    var markerRadius;

    function initialize(screenWidth, screenHeight, tinyFontHeight) {
        width = screenWidth;
        height = screenHeight;
        centerX = screenWidth / 2;
        centerY = screenHeight / 2;
        var compact = screenWidth <= 260;
        titleY = compact ? 2 : 8;
        footerY = compact ? screenHeight - 14 : screenHeight - 40;
        drawableTop = compact ? tinyFontHeight + 15 : 58;
        drawableBottom = compact ? screenHeight - tinyFontHeight - 8 : screenHeight - 64;
        rowPitch = compact ? tinyFontHeight + 6 : 42;
        rowLeft = compact ? (screenWidth * 14) / 100 : 54;
        rowRight = compact ? screenWidth - rowLeft : screenWidth - 54;
        labelX = rowLeft + (compact ? 7 : 22);
        valueX = rowRight - (compact ? 7 : 18);
        contentWidth = rowRight - rowLeft;
        detailWidth = contentWidth - (compact ? 14 : 44);
        reticleRadius = (screenWidth < screenHeight ? screenWidth : screenHeight) * 170.0 / 454.0;
        reticleSafeRadius = (screenWidth < screenHeight ? screenWidth : screenHeight) / 2.0 - (compact ? 3.0 : 5.0);
        markerRadius = compact ? 4 : 6;
    }

    function y(referenceY) {
        return (referenceY * height) / 454;
    }

    function rowTop(referenceY, rowHalfHeight) {
        var top = y(referenceY);
        var minimum = drawableTop + rowHalfHeight;
        return top < minimum ? minimum : top;
    }
}
