import Toybox.Application;
import Toybox.Time;

class PolarFinderModel {
  var latitude=null; var longitude=null; var elevation=null; var source=""; var quality=""; var savedAt=null;
  var confirmed=false; var formatDms=false; var pressureMode=0; var manualPressure=1013.25; var manualPressureSet=false;
  var temperature=10.0; var humidity=50.0; var calculationAlert=true; var firstUse=true; var adjusted=false;
  var savedLatitude=null; var savedLongitude=null; var savedElevation=null; var savedSource=""; var savedQuality="";

  function initialize() { load(); }
  function valueOr(value,fallback) { return value==null?fallback:value; }
  function load() {
    latitude=Application.Storage.getValue("latitude"); longitude=Application.Storage.getValue("longitude"); elevation=Application.Storage.getValue("elevation");
    if(hasLocation()){source=valueOr(Application.Storage.getValue("source"),"Saved");quality=valueOr(Application.Storage.getValue("quality"),"");savedAt=Application.Storage.getValue("savedAt");}
    formatDms=valueOr(Application.Storage.getValue("formatDms"),false); pressureMode=valueOr(Application.Storage.getValue("pressureMode"),0).toNumber();if(pressureMode<0||pressureMode>2){pressureMode=0;}
    manualPressure=valueOr(Application.Storage.getValue("manualPressure"),1013.25); manualPressureSet=valueOr(Application.Storage.getValue("manualPressureSet"),false); temperature=valueOr(Application.Storage.getValue("temperature"),10.0);
    humidity=valueOr(Application.Storage.getValue("humidity"),50.0); calculationAlert=valueOr(Application.Storage.getValue("calculationAlert"),true); firstUse=valueOr(Application.Storage.getValue("firstUse"),true);
    captureSaved(); confirmed=false;
  }
  function hasLocation(){return latitude!=null&&longitude!=null&&elevation!=null;}
  function captureSaved(){savedLatitude=latitude;savedLongitude=longitude;savedElevation=elevation;savedSource=source;savedQuality=quality;}
  function differs(a,b){if(a==null||b==null){return a!=b;}return (a-b).abs()>0.00000001;}
  function hasUnconfirmedChanges(){return differs(latitude,savedLatitude)||differs(longitude,savedLongitude)||differs(elevation,savedElevation)||source!=savedSource||quality!=savedQuality;}
  function discardLocationChanges(){latitude=savedLatitude;longitude=savedLongitude;elevation=savedElevation;source=savedSource;quality=savedQuality;adjusted=false;confirmed=false;}
  function setLocation(lat,lon,elev,newSource,newQuality){latitude=lat;longitude=lon;elevation=elev;source=newSource;quality=newQuality;confirmed=false;adjusted=false;}
  function confirm(){if(!hasLocation()){return;}confirmed=true;savedAt=Time.now().value();Application.Storage.setValue("latitude",latitude);Application.Storage.setValue("longitude",longitude);Application.Storage.setValue("elevation",elevation);Application.Storage.setValue("source",source);Application.Storage.setValue("quality",quality);Application.Storage.setValue("savedAt",savedAt);captureSaved();savePreferences();}
  function savePreferences(){Application.Storage.setValue("formatDms",formatDms);Application.Storage.setValue("pressureMode",pressureMode);Application.Storage.setValue("manualPressure",manualPressure);Application.Storage.setValue("manualPressureSet",manualPressureSet);Application.Storage.setValue("temperature",temperature);Application.Storage.setValue("humidity",humidity);Application.Storage.setValue("calculationAlert",calculationAlert);Application.Storage.setValue("firstUse",firstUse);}
  function calculationSucceeded(){firstUse=false;Application.Storage.setValue("firstUse",false);}
}
