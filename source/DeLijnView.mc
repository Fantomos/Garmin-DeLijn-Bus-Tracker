using Toybox.Graphics as Gfx;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Timer;

//! Shows the web request result
class DeLijnView extends WatchUi.View {
  private var _message as String = "Press menu or\nselect button";
  private var _timetable = [];
  private var _countdownString = [
    [{"time" => "--:--", "color" => Gfx.COLOR_WHITE}, {"time" => "--:--", "color" => Gfx.COLOR_WHITE}],
    [{"time" => "--:--", "color" => Gfx.COLOR_WHITE}, {"time" => "--:--", "color" => Gfx.COLOR_WHITE}],
  ];
  private var _favCountdown1_1;
  private var _favCountdown1_2;
  private var _favCountdown2_1;
  private var _favCountdown2_2;
  private var _favName1;
  private var _favName2;
  private var _refreshUITimer;

  //! Constructor
  public function initialize() {
    WatchUi.View.initialize();
    _refreshUITimer = new Timer.Timer();
  }

  //! Load your resources here
  //! @param dc Device context
  public function onLayout(dc as Gfx.Dc) as Void {
    setLayout(Rez.Layouts.MainLayout(dc));
    _favCountdown1_1 = View.findDrawableById("favCountdown1_1") as TextArea;
    _favCountdown1_2 = View.findDrawableById("favCountdown1_2") as TextArea;
    _favCountdown2_1 = View.findDrawableById("favCountdown2_1") as TextArea;
    _favCountdown2_2 = View.findDrawableById("favCountdown2_2") as TextArea;
    _favName1 = View.findDrawableById("favName1") as TextArea;
    _favName2 = View.findDrawableById("favName2") as TextArea;

    _favName1.setText(Application.getApp().getProperty("favorite1Name"));
    _favName2.setText(Application.getApp().getProperty("favorite2Name"));
  }

  //! Restore the state of the app and prepare the view to be shown
  public function onShow() as Void {
    _refreshUITimer.start(method(:onRefresh), 1000, true);
  }

  //! Update the view
  //! @param dc Device Context
  public function onUpdate(dc as Gfx.Dc) as Void {
    _updateCountdowns();
    _favCountdown1_1.setText(_countdownString[0][0]["time"]);
    _favCountdown1_1.setColor(_countdownString[0][0]["color"]);
    _favCountdown1_2.setText(_countdownString[0][1]["time"]);
    _favCountdown1_2.setColor(_countdownString[0][1]["color"]);
    _favCountdown2_1.setText(_countdownString[1][0]["time"]);
    _favCountdown2_1.setColor(_countdownString[1][0]["color"]);
    _favCountdown2_2.setText(_countdownString[1][1]["time"]);
    _favCountdown2_2.setColor(_countdownString[1][1]["color"]);
    View.onUpdate(dc);
  }

  //! Called when this View is removed from the screen. Save the
  //! state of your app here.
  public function onHide() as Void {
    _refreshUITimer.stop();
  }

  //! Show the result or status of the web request
  //! @param args Data from the web request, or error message
  public function onReceive(args as Dictionary or String or Null) as Void {
    if (args instanceof Array) {
      _timetable = args;
      onRefresh();
    }
  }

  public function onRefresh() as Void {
    WatchUi.requestUpdate();
  }

  private function _statusToColor(status as String) as Number {
    if(status == null) {
      return Gfx.COLOR_WHITE;
    }
    switch (status) {
        case "LATE":
          return Gfx.COLOR_RED; 
        case "ON_TIME":
          return Gfx.COLOR_GREEN;
        case "EARLY":
          return Gfx.COLOR_PURPLE;       
        default:
          return Gfx.COLOR_WHITE;
    }
  }

  private function _updateCountdowns() as Void {
    var now = Time.now();
      for (var i = 0; i < _timetable.size(); i++) {
        for (var j = 0; j < _timetable[i]["data"].size(); j++) {
          var time =  _timetable[i]["data"][j]["time"];
          _countdownString[i][j]["color"] = _statusToColor(_timetable[i]["data"][j]["status"]);
          if (time == null) {
            _countdownString[i][j]["time"] = "--";
          }
          else if (now.greaterThan(time)){
             _countdownString[i][j]["time"] = "00";
          }
          else {
              var countdown = now.subtract(time).value();
              if(countdown > 5940) {
                countdown = 5940;
              }
              _countdownString[i][j]["time"] = Lang.format("$1$", [
              (countdown / 60).format("%02d")
            ]);
          }
        }
      }
      System.println(_countdownString);
  }
}
