import Toybox.Communications;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application;
using Toybox.Time.Gregorian;

//! Creates a web request on menu / select events
class DeLijnDelegate extends WatchUi.BehaviorDelegate {
  private var _notify as (Method(args as Dictionary or String or Null) as Void);
  private var _refreshRequestTimer;
  private var _apiKey = Application.getApp().getProperty("apiKey");
  private var _timetable = [
    {
      "name" => Application.getApp().getProperty("favorite1Name"),
      "data" => [ 
        {
          "status" => null,
          "time" => null,
        },
        {
          "status" => null,
          "time" => null,
        }        
      ],
    },
    {
      "name" => Application.getApp().getProperty("favorite2Name"),
      "data" => [ 
        {
          "status" => null,
          "time" => null,
        },
        {
          "status" => null,
          "time" => null,
        }        
      ],
    },
  ];
  private var _request = [
    {
      "line" => Application.getApp().getProperty("favorite1LineID"),
      "url" => "https://api.delijn.be/DLKernOpenData/api/v1/haltes/" +
      Application.getApp().getProperty("favorite1Region") +
      "/" +
      Application.getApp().getProperty("favorite1StopID") +
      "/real-time?maxAantalDoorkomsten=20",
    },
    {
      "line" => Application.getApp().getProperty("favorite2LineID"),
      "url" => "https://api.delijn.be/DLKernOpenData/api/v1/haltes/" +
      Application.getApp().getProperty("favorite2Region") +
      "/" +
      Application.getApp().getProperty("favorite2StopID") +
      "/real-time?maxAantalDoorkomsten=20",
    },
  ];

  enum {
    ADVANCE,
    LATE,
    NO_REALTIME,
  }

  //! Set up the callback to the view
  //! @param handler Callback method for when data is received
  public function initialize(
    handler as (Method(args as Dictionary or String or Null) as Void)
  ) {
    WatchUi.BehaviorDelegate.initialize();
    _notify = handler;
    _refreshRequestTimer = new Timer.Timer();
    _refreshRequestTimer.start(method(:onRequest), Application.getApp().getProperty("refreshTime")*1000, true);
     onRequest();
  }

  //! On a menu event, make a web request
  //! @return true if handled, false otherwise
  public function onMenu() as Boolean {
    onRequest();
    return true;
  }

  //! On a select event, make a web request
  //! @return true if handled, false otherwise
  public function onSelect() as Boolean {
    onRequest();
    return true;
  }

  //! Receive the data from the web request
  //! @param responseCode The server response code
  //! @param data Content from a successful request
  public function onReceiveFirstRequest(responseCode as Number, data as Dictionary or String or Null) as Void {
    if (responseCode == 200) {
      var index = 0;
      for (var i = 0; i < data["halteDoorkomsten"][0]["doorkomsten"].size(); i++) {
        var report = data["halteDoorkomsten"][0]["doorkomsten"][i];
        if (report["lijnnummer"] == _request[0]["line"]) {
          var stopTime = _parseDate(report["real-timeTijdstip"]);
          var stopStaticTime = _parseDate(report["dienstregelingTijdstip"]);

          if(stopTime == null) {
            stopTime = stopStaticTime;
            _timetable[0]["data"][index]["status"] = "NO_TIME";
          }
          else {
            var diffTime = stopStaticTime.compare(stopTime);
            if(diffTime < 0) {
               _timetable[0]["data"][index]["status"] = "LATE";
            }
            else if(diffTime == 0) {
              _timetable[0]["data"][index]["status"] = "ON_TIME";
            }
            else {
              _timetable[0]["data"][index]["status"] = "EARLY";
            }
          }

          if(stopTime != null) {
            _timetable[0]["data"][index]["time"] = stopTime;
            index++;
          }

          if (index == 2) {
            break;
          }
        }
      }
      
      _notify.invoke(_timetable);
    }
  }

  //! Receive the data from the web request
  //! @param responseCode The server response code
  //! @param data Content from a successful request
  public function onReceiveSecondRequest(responseCode as Number, data as Dictionary or String or Null) as Void {
     if (responseCode == 200) {
      var index = 0;
      for (var i = 0; i < data["halteDoorkomsten"][0]["doorkomsten"].size(); i++) {
        var report = data["halteDoorkomsten"][0]["doorkomsten"][i];
        if (report["lijnnummer"] == _request[1]["line"]) {
          var stopTime = _parseDate(report["real-timeTijdstip"]);
          var stopStaticTime = _parseDate(report["dienstregelingTijdstip"]);

          if(stopTime == null) {
            stopTime = stopStaticTime;
            _timetable[1]["data"][index]["status"] = "NO_TIME";
          }
          else {
            var diffTime = stopTime.compare(stopStaticTime);
            if(diffTime < 0) {
               _timetable[1]["data"][index]["status"] = "LATE";
            }
            else if(diffTime == 0) {
              _timetable[1]["data"][index]["status"] = "ON_TIME";
            }
            else {
              _timetable[1]["data"][index]["status"] = "EARLY";
            }
          }

          if(stopTime != null) {
            _timetable[1]["data"][index]["time"] = stopTime;
            index++;
          }

          if (index == 2) {
            break;
          }
        }
      }
      
      _notify.invoke(_timetable);
    }
  }

  //! Make the web request
  public function onRequest() as Void {
    var options = {
      :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
      :headers => {
        "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
        "Ocp-Apim-Subscription-Key" => _apiKey,
      },
    };

    Communications.makeWebRequest(
      _request[0]["url"],
      null,
      options,
      method(:onReceiveFirstRequest)
    );

      Communications.makeWebRequest(
      _request[1]["url"],
      null,
      options,
      method(:onReceiveSecondRequest)
    );
  }

  private function _parseDate(date as String) {
    // 2025-02-17T20:30:55
    if (!(date instanceof String) || date.length() != 19) {
      return null;
    }

    return Gregorian.moment({
      :year => date.substring(0, 4).toNumber(),
      :month => date.substring(5, 7).toNumber(),
      :day => date.substring(8, 10).toNumber(),
      :hour => date.substring(11, 13).toNumber(),
      :minute => date.substring(14, 16).toNumber(),
      :second => date.substring(17, 19).toNumber(),
    }).subtract(new Time.Duration(3600));
  }
}
