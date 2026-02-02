pragma ComponentBehavior: Bound

import QtQuick

// These functions are here if they used by 2 qml files or more

Item{
    id: root

    function customDateTimeFormatting(fullDateTime, customStringFormat){
        const regex = /\$\{([^}]+)\}/g; // take all elements with ${*}, * = text with 1 character or more
        let format = customStringFormat;

        const array = [];
        const matches = format.match(regex, format); // match with all ${*} and put that in an array, return null if no match
        if (matches){
            matches.forEach((elem) => { 
                array.push(elem.slice(2, -1)); // remove "${" and "}" for each elements
            });
        }
        format = format.replace(regex, "/ꟽ"); // replace ${*} by / and a random rarely used latin character (here ꟽ: U+A7FD)

        let transform = Qt.locale().toString(fullDateTime, format); // date/time transformation with Qt

        let index = 0;
        array.forEach((elem) => { 
            transform = transform.replace(/\/ꟽ/i, array[index]); // replace each /ꟽ by array elements
            index++;
        });

        return transform;
    }


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

        return useSeconds ? resultSec : result;
    }
}
 