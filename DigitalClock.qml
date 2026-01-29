/*
    SPDX-FileCopyrightText: 2013 Heena Mahour <heena393@gmail.com>
    SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2013 Martin Klapetek <mklapetek@kde.org>
    SPDX-FileCopyrightText: 2014 David Edmundson <davidedmundson@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.private.digitalclock
import org.kde.kirigami as Kirigami
import org.kde.plasma.clock


MouseArea {
    id: main
    objectName: "digital-clock-compactrepresentation"

    property string timeFormat
    property string timeFormatWithSeconds

    TimeFormat {
        id: timeFormatFile
    }

    // This is quite convoluted in Qt 6:
    // Qt.formatDate with locale only accepts Locale.FormatType as format type,
    // no Qt.DateFormat (ISODate) and no format string.
    // Locale.toString on the other hand only formats a date *with* time...
    readonly property var dateFormatter: {
        if (Plasmoid.configuration.dateFormat === "custom") {
            Plasmoid.configuration.customDateFormat; // create a binding dependency on this property.
            return (d) => {
                return Qt.locale().toString(d, Plasmoid.configuration.customDateFormat);
            };
        } else if (Plasmoid.configuration.dateFormat === "isoDate") {
            return (d) => {
                return Qt.formatDate(d, Qt.ISODate);
            };
        } else if (Plasmoid.configuration.dateFormat === "longDate") {
            return (d) => {
                return Qt.formatDate(d, Qt.locale(), Locale.LongFormat);
            };
        } else {
            return (d) => {
                return Qt.formatDate(d, Qt.locale(), Locale.ShortFormat);
            };
        }
    }


    readonly property var timeFormatter: {
        Plasmoid.configuration.customTimeFormat;
        // for the 3rd parameter, all values except -1, 0, 1, 2 force regionalTimeFormat
        return (d, showSecondsEnabled = false, forceTimeFormat = -1) => {
            const textTimeFormatter = Plasmoid.configuration.timeFormat;
            let valueTimeFormatter;
            if (forceTimeFormat !== -1){
                valueTimeFormatter =  forceTimeFormat;
            } else {
                switch(textTimeFormatter){
                    case "timeCustom":
                        valueTimeFormatter = 0;
                        break;
                    case "time12h":
                        valueTimeFormatter = 1;
                        break;
                    case "time24h":
                        valueTimeFormatter = 2;
                        break;
                    // any other numbers =>  regional format
                }
            }


            if (valueTimeFormatter === 0) {
                return Qt.locale().toString(d, Plasmoid.configuration.customTimeFormat);
            } else if (valueTimeFormatter === 1){
                let seconds = showSecondsEnabled ? ":ss" : "";
                let time = "hh:mm" + seconds + " AP";
                return Qt.formatTime(d, time);
            } else if (valueTimeFormatter === 2){
                let seconds = showSecondsEnabled ? ":ss" : "";
                let time = "hh:mm" + seconds;
                return Qt.formatTime(d, time);
            } else {
                const timeFormat = timeFormatCorrectionFunction(Qt.locale().timeFormat(Locale.ShortFormat), showSecondsEnabled, true);
                return Qt.formatTime(d, timeFormat);
            } 
        }
    }


    property string lastDate: ""
    property string lastDateFormatter: ""
    property string lastTimeFormatter: ""
    property int tzOffset

    // This is the index in the list of user selected time zones
    property int tzIndex: 0

    // if showing the date and the time in one line or
    // if the date/time zone cannot be fit with the smallest font to its designated space
    readonly property bool oneLineMode: {
        if (Plasmoid.configuration.informationDisplay !== 2){
            return true;
        } else {
            // 0 or 1 -> 2 lines, 2 or 3 -> 1 line
            const value = parseInt(Plasmoid.configuration.informationDisplayFormat);
            return (value === 2 || value === 3);
        }
        
    }

    property bool wasExpanded
    property int wheelDelta: 0

    Accessible.role: Accessible.Button
    Accessible.onPressAction: clicked(null)

    Clock {
        id: clock
        timeZone: Plasmoid.configuration.lastSelectedTimezone
        // useless to track seconds if it shows nowhere
        trackSeconds: !(Plasmoid.configuration.showSeconds === 0 && (Plasmoid.configuration.timeFormat === "timeCustom" && 
            !(Plasmoid.configuration.customTimeFormat.contains("s") || Plasmoid.configuration.customTimeFormat.contains("ss")))) 
        onDateTimeChanged: main.dateTimeChanged()
        onTimeZoneChanged: main.setupLabels()
    }

    Connections {
        target: Plasmoid
        function onContextualActionsAboutToShow() {
            ClipboardMenu.secondsIncluded = (Plasmoid.configuration.showSeconds === 2);
            ClipboardMenu.currentDate = clock.dateTime;
        }
    }

    Connections {
        target: Plasmoid.configuration
        function onSelectedTimeZonesChanged() {
            // If the currently selected time zone was removed,
            // default to the first one in the list
            if (Plasmoid.configuration.selectedTimeZones.indexOf(Plasmoid.configuration.lastSelectedTimezone) === -1) {
                Plasmoid.configuration.lastSelectedTimezone = Plasmoid.configuration.selectedTimeZones[0];
            }

            main.setupLabels();
            main.setTimeZoneIndex();
        }

        function onDisplayTimezoneFormatChanged() {
            main.setupLabels();
        }

        function onLastSelectedTimezoneChanged() {
            main.timeFormatCorrectionFunction();
        }

        function onShowLocalTimezoneChanged() {
            main.timeFormatCorrectionFunction();
        }

        function onShowDateChanged() {
            main.timeFormatCorrectionFunction();
        }

        function onUse24hFormatChanged() {
            main.timeFormatCorrectionFunction();
        }
    }


    

    function pointToPixel(pointSize: int): int {
        const pixelsPerInch = Screen.pixelDensity * 25.4
        return Math.round(pointSize / 72 * pixelsPerInch)
    }

    states: [
        State {
            name: "horizontalPanel"
            when: Plasmoid.formFactor === PlasmaCore.Types.Horizontal && !main.oneLineMode

            PropertyChanges {
                main.Layout.fillHeight: true
                main.Layout.fillWidth: false
                main.Layout.minimumWidth: contentItem.width
                main.Layout.maximumWidth: main.Layout.minimumWidth

                contentItem.height: timeLabel.height + 0.8 * timeLabel.height
                contentItem.width: Math.max(timeLabel.paintedWidth + Kirigami.Units.mediumSpacing , dateLabel.paintedWidth + Kirigami.Units.mediumSpacing);

                labelsGrid.rows: 1 
                //labelsGrid.rows: labelsGrid.Plasmoid.configuration.showDate ? 1 : 2

                timeLabel.height: sizehelper.height
                timeLabel.width: sizehelper.contentWidth
                timeLabel.font.pixelSize: timeLabel.height


                timeZoneLabel.height: 0.7 * timeLabel.height
                timeZoneLabel.width: timeZoneLabel.paintedWidth
                timeZoneLabel.font.pixelSize: timeZoneLabel.height

                dateLabel.height: 0.8 * timeLabel.height
                dateLabel.width: dateLabel.paintedWidth
                dateLabel.verticalAlignment: Text.AlignVCenter
                dateLabel.font.pixelSize: dateLabel.height

                /*
                 * The value 0.71 was picked by testing to give the clock the right
                 * size (aligned with tray icons).
                 * Value 0.56 seems to be chosen rather arbitrary as well such that
                 * the time label is slightly larger than the date or time zone label
                 * and still fits well into the panel with all the applied margins.
                 */
                 sizehelper.height: Math.min(main.height * 0.56, fontHelper.font.pixelSize)
                //sizehelper.height: Math.min(timeZoneLabel.Plasmoid.configuration.showDate || timeZoneLabel.visible ? main.height * 0.56 : main.height * 0.71,
                //                            fontHelper.font.pixelSize)

                sizehelper.font.pixelSize: sizehelper.height
            }

            AnchorChanges {
                target: labelsGrid

                anchors.horizontalCenter: contentItem.horizontalCenter
            }

            AnchorChanges {
                target: dateLabel

                anchors.top: labelsGrid.bottom
                anchors.horizontalCenter: labelsGrid.horizontalCenter
            }
        },

        State {
            name: "oneLineDate"
            // the one-line mode has no effect on a vertical panel because it would never fit
            when: Plasmoid.formFactor !== PlasmaCore.Types.Vertical && main.oneLineMode

            PropertyChanges {
                main.Layout.fillHeight: true
                main.Layout.fillWidth: false
                main.Layout.minimumWidth: contentItem.width
                main.Layout.maximumWidth: main.Layout.minimumWidth
                anchors.horizontalCenter: main.horizontalCenter

                contentItem.height: sizehelper.height
                contentItem.width: timeLabel.paintedWidth;

                dateLabel.height: timeLabel.height
                dateLabel.width: dateLabel.paintedWidth

                dateLabel.font.pixelSize: 1024
                dateLabel.verticalAlignment: Text.AlignVCenter
                // between date and time; they are styled the same, so
                // a space is more appropriate than smallSpacing
                //dateLabel.anchors.rightMargin: timeMetrics.advanceWidth(" ")
                //dateLabel.fontSizeMode: Text.VerticalFit

                timeLabel.height: sizehelper.height
                timeLabel.width: timeLabel.paintedWidth//sizehelper.contentWidth
                timeLabel.fontSizeMode: Text.VerticalFit

                timeZoneLabel.height: 0.7 * timeLabel.height
                timeZoneLabel.width: timeZoneLabel.paintedWidth
                timeZoneLabel.fontSizeMode: Text.VerticalFit
                timeZoneLabel.horizontalAlignment: Text.AlignHCenter

                sizehelper.height: Math.min(main.height, fontHelper.contentHeight)
                sizehelper.fontSizeMode: Text.VerticalFit
                sizehelper.font.pixelSize: fontHelper.font.pixelSize
            }

            AnchorChanges {
                target: labelsGrid

                anchors.right: contentItem.right
            }

            AnchorChanges {
                target: dateLabel

                anchors.right: labelsGrid.left
                anchors.verticalCenter: labelsGrid.verticalCenter
            }
        },

        State {
            name: "verticalPanel"
            when: Plasmoid.formFactor === PlasmaCore.Types.Vertical

            PropertyChanges {
                id: verticalPanel

                main.Layout.fillHeight: false
                main.Layout.fillWidth: true
                main.Layout.maximumHeight: contentItem.height
                main.Layout.minimumHeight: main.Layout.maximumHeight

                contentItem.height: main.oneLineMode ? labelsGrid.height : labelsGrid.height + dateLabel.contentHeight
                contentItem.width: main.width

                labelsGrid.rows: 2

                timeLabel.height: sizehelper.contentHeight
                timeLabel.width: main.width
                timeLabel.font.pixelSize: Math.min(timeLabel.height, fontHelper.font.pixelSize)
                timeLabel.fontSizeMode: Text.Fit
                timeLabel.elide: Text.ElideRight;
                

                timeZoneLabel.height: Math.max(0.7 * timeLabel.height, dateLabel.minimumPixelSize)
                timeZoneLabel.width: main.width
                timeZoneLabel.fontSizeMode: Text.Fit
                timeZoneLabel.minimumPixelSize: dateLabel.minimumPixelSize
                timeZoneLabel.elide: Text.ElideRight

                dateLabel.width: main.width
                //NOTE: in order for Text.Fit to work as intended, the actual height needs to be quite big, in order for the font to enlarge as much it needs for the available width, and then request a sensible height, for which contentHeight will need to be considered as opposed to height
                dateLabel.height: sizehelper.contentHeight//Kirigami.Units.gridUnit * 10
                dateLabel.fontSizeMode: Text.Fit
                dateLabel.verticalAlignment: Text.AlignTop; //parseInt(Plasmoid.configuration.informationDisplayFormat) === 1 ? Text.AlignTop : Text.AlignVCenter;
                // Those magic numbers are purely what looks nice as maximum size, here we have it the smallest
                // between slightly bigger than the default font (1.4 times) and a bit smaller than the time font
                dateLabel.font.pixelSize: Math.min(0.7 * timeLabel.height, contentItem.Kirigami.Theme.defaultFont.pixelSize * 1.4)
                dateLabel.elide: Text.ElideRight
                dateLabel.wrapMode: Text.WordWrap

                sizehelper.width: main.width
                sizehelper.fontSizeMode: Text.HorizontalFit
                sizehelper.font.pixelSize: fontHelper.font.pixelSize

            }

            AnchorChanges {
                target: dateLabel

                anchors.top: labelsGrid.bottom
                anchors.horizontalCenter: labelsGrid.horizontalCenter
            }

            
            
            
        },

        State {
            name: "other"
            when: Plasmoid.formFactor !== PlasmaCore.Types.Vertical && Plasmoid.formFactor !== PlasmaCore.Types.Horizontal

            PropertyChanges {
                main.Layout.fillHeight: false
                main.Layout.fillWidth: false
                main.Layout.minimumWidth: Kirigami.Units.gridUnit * 3
                main.Layout.minimumHeight: Kirigami.Units.gridUnit * 3

                contentItem.height: main.height
                contentItem.width: main.width

                labelsGrid.rows: 2

                timeLabel.height: sizehelper.height
                timeLabel.width: main.width
                timeLabel.fontSizeMode: Text.Fit

                timeZoneLabel.height: 0.7 * timeLabel.height
                timeZoneLabel.width: main.width
                timeZoneLabel.fontSizeMode: Text.Fit
                timeZoneLabel.minimumPixelSize: 1

                dateLabel.height: 0.7 * timeLabel.height
                dateLabel.font.pixelSize: 1024
                dateLabel.width: Math.max(timeLabel.contentWidth, Kirigami.Units.gridUnit * 3)
                dateLabel.verticalAlignment: Text.AlignVCenter
                dateLabel.fontSizeMode: Text.Fit
                dateLabel.minimumPixelSize: 1
                dateLabel.wrapMode: Text.WordWrap

                sizehelper.height: {
                    if (main.oneLineMode) {
                        if (timeZoneLabel.visible) {
                            return 0.4 * main.height
                        }
                        return 0.56 * main.height
                    } else if (timeZoneLabel.visible) {
                        return 0.59 * main.height
                    }
                    return main.height
                }
                sizehelper.width: main.width
                sizehelper.fontSizeMode: Text.Fit
                sizehelper.font.pixelSize: 1024
            }

            AnchorChanges {
                target: dateLabel

                anchors.top: labelsGrid.bottom
                anchors.horizontalCenter: labelsGrid.horizontalCenter
            }
        }
    ]

    onStateChanged: {
        updateVerticalLayout();
    }

    onPressed: wasExpanded = root.expanded
    onClicked: root.expanded = !wasExpanded
    onWheel: wheel => {
        if (!Plasmoid.configuration.wheelChangesTimezone) {
            return;
        }

        var delta = (wheel.inverted ? -1 : 1) * (wheel.angleDelta.y ? wheel.angleDelta.y : wheel.angleDelta.x);
        var newIndex = tzIndex;
        wheelDelta += delta;
        // magic number 120 for common "one click"
        // See: https://doc.qt.io/qt-5/qml-qtquick-wheelevent.html#angleDelta-prop
        while (wheelDelta >= 120) {
            wheelDelta -= 120;
            newIndex--;
        }
        while (wheelDelta <= -120) {
            wheelDelta += 120;
            newIndex++;
        }

        if (newIndex >= Plasmoid.configuration.selectedTimeZones.length) {
            newIndex = 0;
        } else if (newIndex < 0) {
            newIndex = Plasmoid.configuration.selectedTimeZones.length - 1;
        }

        if (newIndex !== tzIndex) {
            Plasmoid.configuration.lastSelectedTimezone = Plasmoid.configuration.selectedTimeZones[newIndex];
            tzIndex = newIndex;
        }
    }

   /*
    * Visible elements
    *
    */
    Item {
        id: contentItem
        anchors.verticalCenter: main.verticalCenter
        //anchors.horizontalCenter: main.horizontalCenter
        //width: main.width
        //height: childrenRect.heigh

        Grid {
            id: labelsGrid

            rows: 1
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter

            flow: Grid.TopToBottom
            // between time and timezone; timezone is styled differently, so
            // smallSpacing is more appropriate than a space
            columnSpacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Label  {
                id: timeLabel

                font {
                    family: fontHelper.font.family
                    weight: fontHelper.font.weight
                    italic: fontHelper.font.italic
                    features: { "tnum": 1 }
                    pixelSize: 1024
                }
                minimumPixelSize: 1

                text: Qt.formatTime(clock.dateTime, Plasmoid.configuration.showSeconds === 2 ? main.timeFormatWithSeconds : main.timeFormat)
                textFormat: Text.PlainText

                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
            }

            PlasmaComponents.Label {
                id: timeZoneLabel

                font.weight: timeLabel.font.weight
                font.italic: timeLabel.font.italic
                font.pixelSize: 1024
                minimumPixelSize: 1

                visible: text.length > 0
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                textFormat: Text.PlainText
            }
        }

        PlasmaComponents.Label {
            id: dateLabel

            visible: true

            font.family: timeLabel.font.family
            font.weight: timeLabel.font.weight
            font.italic: timeLabel.font.italic
            font.pixelSize: 1024
            minimumPixelSize: 1

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.PlainText
        }
    }
    /*
     * end: Visible Elements
     *
     */

    PlasmaComponents.Label {
        id: sizehelper

        font.family: timeLabel.font.family
        font.weight: timeLabel.font.weight
        font.italic: timeLabel.font.italic
        minimumPixelSize: 1

        visible: false
        textFormat: Text.PlainText
    }

    // To measure Label.height for maximum-sized font in VerticalFit mode
    PlasmaComponents.Label {
        id: fontHelper

        height: 1024

        font.family: (Plasmoid.configuration.autoFontAndSize || Plasmoid.configuration.fontFamily.length === 0) ? Kirigami.Theme.defaultFont.family : Plasmoid.configuration.fontFamily
        font.weight: Plasmoid.configuration.autoFontAndSize ? Kirigami.Theme.defaultFont.weight : Plasmoid.configuration.fontWeight
        font.italic: Plasmoid.configuration.autoFontAndSize ? Kirigami.Theme.defaultFont.italic : Plasmoid.configuration.italicText
        font.pixelSize: Plasmoid.configuration.autoFontAndSize ? 3 * Kirigami.Theme.defaultFont.pixelSize : main.pointToPixel(Plasmoid.configuration.fontSize)
        fontSizeMode: Text.VerticalFit

        visible: false
        textFormat: Text.PlainText
    }

    FontMetrics {
        id: timeMetrics

        font.family: timeLabel.font.family
        font.weight: timeLabel.font.weight
        font.italic: timeLabel.font.italic
    }

    function updateVerticalLayout() {
        if (Plasmoid.formFactor === PlasmaCore.Types.Vertical){
            if (parseInt(Plasmoid.configuration.informationDisplayFormat) === 0){ // time top
                dateLabel.verticalAlignment = Text.AlignBottom;

                timeLabel.verticalAlignment = Text.AlignTop;
            } else if (parseInt(Plasmoid.configuration.informationDisplayFormat) === 1){ // date top
                timeLabel.wrapMode = Text.WordWrap;
                timeLabel.verticalAlignment = Text.AlignBottom;

                dateLabel.wrapMode = Text.NoWrap
                dateLabel.verticalAlignment = Text.AlignTop;
            }
        }
    }



    
    function timeFormatCorrectionFunction(timeFormatString = Qt.locale().timeFormat(Locale.ShortFormat), useSeconds = true, returnResult = false) {
        const timeFormatResult = timeFormatFile.timeFormatCorrection(timeFormatString, useSeconds);
        
        if (returnResult)
            return timeFormatResult
        setupLabels();
    }



    
    function timeFormatUpdate(timeFormatString = Qt.locale().timeFormat(Locale.ShortFormat)) {
        timeFormat = main.timeFormatter(clock.dateTime, false, 3).replace(/am|pm|AM|PM/g, "AP");
        timeFormatWithSeconds = main.timeFormatter(clock.dateTime, true, 3).replace(/am|pm|AM|PM/g, "AP");
        setupLabels();
    }

    function setupPositionDateAndTime(currentDate, currentTime, positionNumber){
        // positions:
        // 0 -> time top, date bottom (plasma default)
        // 1 -> date top, time bottom
        // 2 -> time left, date right (one line)
        // 3 -> date left, time right (one line)
        //console.log("Vertical ?");
        //console.log(Plasmoid.formFactor === PlasmaCore.Types.Vertical);
        const space = Plasmoid.formFactor === PlasmaCore.Types.Vertical ? "" : " ";
        switch(positionNumber){
            case 0:
                timeLabel.text = space + currentTime + space;
                dateLabel.text = space + currentDate + space;
                break;
            case 1:
                timeLabel.text = space + currentDate + space;
                dateLabel.text = space + currentTime + space;
                break;
            case 2:
                timeLabel.text = space + currentTime + "  " + currentDate + space; // add spaces at left and right to center text
                dateLabel.text = "";
                break;
            case 3:
                timeLabel.text = space + currentDate + "  " + currentTime + space;
                dateLabel.text = "";
                break;
        }       
    }

    function setupLabels() {
        const showTimezone = Plasmoid.configuration.showLocalTimezone
            || (Plasmoid.configuration.lastSelectedTimezone !== "Local"
                && !clock.isSystemTimeZone);

        let timezoneString = "";

        if (showTimezone) {
            // format time zone as tz code, city or UTC offset
            switch (Plasmoid.configuration.displayTimezoneFormat) {
            case 0: // Code
                timezoneString = clock.timeZoneCode;
                break;
            case 1: // City
                timezoneString = TimeZonesI18n.i18nCity(clock.timeZone);
                break;
            case 2: // Offset from UTC time
                timezoneString = clock.timeZoneOffset;
                break;
            }
            if ( Plasmoid.formFactor === PlasmaCore.Types.Horizontal) {
                timezoneString = `(${timezoneString})`;
            }
        }
        // an empty string clears the label and that makes it hidden
        timeZoneLabel.text = timezoneString;

        // timeLabel always in top
        // dateLabel always in bottom
        // only dateLabel can be empty (else positionning is bad)
        const display = Plasmoid.configuration.informationDisplay;
        const currentDate = main.dateFormatter(clock.dateTime);
        const currentTime = main.timeFormatter(clock.dateTime, Plasmoid.configuration.showSeconds === 2);
        switch (display){
            case 0: // only date
                timeLabel.text = currentDate;
                dateLabel.text = "";
                break;
            case 1: // only time
                timeLabel.text = currentTime;
                dateLabel.text = "";
                break;
            case 2: { // date + time 
                const position = Plasmoid.configuration.informationDisplayFormat; 
                setupPositionDateAndTime(currentDate, currentTime, parseInt(position)); // need to force "position" to integer
                break;
            } 
        }

        // find widest character between 0 and 9
        let maximumWidthNumber = 0;
        let maximumAdvanceWidth = 0;
        for (let i = 0; i <= 9; i++) {
            const advanceWidth = timeMetrics.advanceWidth(i);
            if (advanceWidth > maximumAdvanceWidth) {
                maximumAdvanceWidth = advanceWidth;
                maximumWidthNumber = i;
            }
        }
        // replace all placeholders with the widest number (two digits)
        const format = (Plasmoid.configuration.showSeconds === 2 ? main.timeFormatWithSeconds : main.timeFormat).replace(/(h+|m+|s+)/g, "" + maximumWidthNumber + maximumWidthNumber); // make sure maximumWidthNumber is formatted as string
        // build the time string twice, once with an AM time and once with a PM time
        const date = new Date(2000, 0, 1, 1, 0, 0);
        const timeAm = Qt.formatTime(date, format);
        const advanceWidthAm = timeMetrics.advanceWidth(timeAm);
        date.setHours(13);
        const timePm = Qt.formatTime(date, format);
        const advanceWidthPm = timeMetrics.advanceWidth(timePm);
        // set the sizehelper's text to the widest time string
        if (advanceWidthAm > advanceWidthPm) {
            sizehelper.text = timeAm;
        } else {
            sizehelper.text = timePm;
        }
        
        fontHelper.text = sizehelper.text;
    }

    function dateTimeChanged() {
        let doCorrections = false;

        
        // If the date or time has changed, force size recalculation
        // The date/month name can now be longer/shorter, so we need to adjust applet size
        // If we don't need to have seconds, it is useless to recalculate everything each seconds
        let currentDate;
        const customTime = Plasmoid.configuration.customTimeFormat;
        const currentTimeFormat = Plasmoid.configuration.timeFormat;
        const currentDateFormat = Plasmoid.configuration.dateFormat;

        if (Plasmoid.configuration.showSeconds === 0 ){
            if (Plasmoid.configuration.timeFormat === "timeCustom" ){
                if (customTime.includes("s") || customTime.includes("ss")){
                    currentDate = Qt.formatDateTime(clock.dateTime, "yyyy-MM-dd ss");
                } else {
                    currentDate = Qt.formatDateTime(clock.dateTime, "yyyy-MM-dd mm");
                }
            } else {
                currentDate = Qt.formatDateTime(clock.dateTime, "yyyy-MM-dd mm");
            }
        } else {
            currentDate = Qt.formatDateTime(clock.dateTime, "yyyy-MM-dd ss");
        }

       
        if  (lastDate !== currentDate) {
            doCorrections = true;
            lastDate = currentDate;
        } else if (lastDateFormatter !== currentDateFormat){
            doCorrections = true;
            lastDateFormatter = currentDateFormat;
        } else if (lastTimeFormatter !== currentTimeFormat){
            doCorrections = true;
            lastTimeFormatter = currentTimeFormat;
        }
        
        

        if (doCorrections) {
            timeFormatUpdate();
        }
    }

    function setTimeZoneIndex() {
        tzIndex = Plasmoid.configuration.selectedTimeZones.indexOf(Plasmoid.configuration.lastSelectedTimezone);
    }

    Component.onCompleted: {
        Plasmoid.configuration.selectedTimeZones = TimeZoneUtils.sortedTimeZones(Plasmoid.configuration.selectedTimeZones);

        setTimeZoneIndex();
        dateTimeChanged();
        timeFormatUpdate();

        dateFormatterChanged
            .connect(setupLabels);

        timeFormatterChanged
            .connect(setupLabels);

        stateChanged
            .connect(setupLabels);

    }
}
