pragma ComponentBehavior: Bound

import QtQuick

// This function is now here becauses it is used by 2 files 

Item{
    id: root


    // Qt's QLocale does not offer any modular time creating like Klocale did
    // eg. no "gimme time with seconds" or "gimme time without seconds and with time zone".
    // QLocale supports only two formats - Long and Short. Long is unusable in many situations
    // and Short does not provide seconds. So if seconds are enabled, we need to add it here.
    //
    // What happens here is that it looks for the delimiter between "h" and "m", takes it
    // and appends it after "mm" and then appends "ss" for the seconds.
    function timeFormatCorrection(timeFormatString = Qt.locale().timeFormat(Locale.ShortFormat), useSeconds = false){
        
        const regexp = /(hh*)(.+)(mm)/i
        const match = regexp.exec(timeFormatString);


        const hours = match[1];
        const delimiter = match[2];
        const minutes = match[3]
        const seconds = "ss";
        const amPm = "AP";
        const uses24hFormatByDefault = timeFormatString.toLowerCase().indexOf("ap") === -1;

        // because QLocale is incredibly stupid and does not convert 12h/24h clock format
        // when uppercase H is used for hours, needs to be h or hh, so toLowerCase()
        let result = hours.toLowerCase() + delimiter + minutes;

        let resultSec = result + delimiter + seconds;

        // add "AM/PM" either if the setting is the default and locale uses it OR if the user unchecked "use 24h format"
        /*
        if ((Plasmoid.configuration.use24hFormat === Qt.PartiallyChecked && !uses24hFormatByDefault) || Plasmoid.configuration.use24hFormat === Qt.Unchecked) {
            result += " " + amPm;
            result_sec += " " + amPm;
        }
        */

        return useSeconds ? resultSec : result;
    }
}
 