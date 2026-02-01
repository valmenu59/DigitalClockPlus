/*
    SPDX-FileCopyrightText: 2013 Bhushan Shah <bhush94@gmail.com>
    SPDX-FileCopyrightText: 2013 Sebastian Kügler <sebas@kde.org>
    SPDX-FileCopyrightText: 2015 Kai Uwe Broulik <kde@privat.broulik.de>
    SPDX-FileCopyrightText: 2023 ivan tkachenko <me@ratijas.tk>

    SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import Qt.labs.platform as Platform

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.config as KConfig
import org.kde.kcmutils as KCMUtils
import org.kde.kirigami as Kirigami


KCMUtils.SimpleKCM {
    id: appearancePage
    property alias cfg_autoFontAndSize: autoFontAndSizeRadioButton.checked

    // boldText and fontStyleName are not used in DigitalClock.qml
    // However, they are necessary to remember the exact font style chosen.
    // Otherwise, when the user open the font dialog again, the style will be lost.
    property alias cfg_fontFamily: fontDialog.fontChosen.family
    property alias cfg_boldText: fontDialog.fontChosen.bold
    property alias cfg_italicText: fontDialog.fontChosen.italic
    property alias cfg_fontWeight: fontDialog.fontChosen.weight
    property alias cfg_fontStyleName: fontDialog.fontChosen.styleName
    property alias cfg_fontSize: fontDialog.fontChosen.pointSize

    
    property alias cfg_showLocalTimezone: showLocalTimeZone.checked
    property alias cfg_displayTimezoneFormat: displayTimeZoneFormat.currentIndex
    property alias cfg_showSeconds: showSecondsComboBox.currentIndex

    property string cfg_dateFormat: "shortDate"
    property alias cfg_customDateFormat: customDateFormat.text

    //added
    property alias cfg_informationDisplayFormat: displayFormat.currentIndex
    property int cfg_informationDisplay
    property string cfg_timeFormat: "timeRegional"
    property alias cfg_customTimeFormat: customTimeFormat.text
    property int cfg_textAlignment

    property real comboBoxWidth: Math.max(showSecondsComboBox.implicitWidth,
                                          displayTimeZoneFormat.implicitWidth,
                                          //use24hFormat.implicitWidth,
                                          //dateDisplayFormat.implicitWidth,
                                          dateFormat.implicitWidth)


    TimeFormat {
        id: timeFormatter
    }


    Kirigami.FormLayout {
        


        QQC2.ButtonGroup {
            id: infoGroup
            buttons: [showOnlyDate, showOnlyTime, showBoth]
        }

        RowLayout{
             Kirigami.FormData.label: i18n("Information:")

            QQC2.RadioButton {
                id: showOnlyDate
                text: i18n("Show only date")
                checked: appearancePage.cfg_informationDisplay == 0
                onToggled: if (checked) appearancePage.cfg_informationDisplay = 0 
                
            }
        }
           

        QQC2.RadioButton {
            id: showOnlyTime
            text: i18n("Show only time")
            checked: appearancePage.cfg_informationDisplay == 1
            onToggled: if (checked) appearancePage.cfg_informationDisplay = 1
        }


        RowLayout {
            spacing: Kirigami.Units.smallSpacing

            QQC2.RadioButton {
                id: showBoth
                text: i18n("Show both")
                checked: appearancePage.cfg_informationDisplay == 2
                onToggled: if (checked) appearancePage.cfg_informationDisplay = 2
            }

            QQC2.ComboBox {
                id: displayFormat
                enabled: showBoth.checked
                //Layout.preferredWidth: appearancePage.comboBoxWidth
                model: [
                    i18n("Time on top, date on bottom"),
                    i18n("Date on top, time on bottom"),
                    i18n("Time on left, date on right"),
                    i18n("Date on left, time on right")
                ]
                currentIndex: appearancePage.cfg_informationDisplayFormat
                onActivated: appearancePage.cfg_informationDisplayFormat = currentIndex
            }
        }
        

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.ComboBox {
            id: showSecondsComboBox
            Layout.preferredWidth: appearancePage.comboBoxWidth
            enabled: appearancePage.cfg_informationDisplay != 0
            Kirigami.FormData.label: i18n("Show seconds:")
            model: [
                i18nc("@option:check", "Never"),
                i18nc("@option:check", "Only in the tooltip"),
                i18n("Always"),
            ]
            onActivated: appearancePage.cfg_showSeconds = currentIndex;
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        ColumnLayout {
            Kirigami.FormData.label: i18n("Show time zone:")
            enabled: appearancePage.cfg_informationDisplay !== 0
            Kirigami.FormData.buddyFor: showLocalTimeZoneWhenDifferent
            spacing: Kirigami.Units.smallSpacing

            QQC2.RadioButton {
                id: showLocalTimeZoneWhenDifferent
                text: i18n("Only when different from local time zone")
            }

            QQC2.RadioButton {
                id: showLocalTimeZone
                text: i18n("Always")
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Settings:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                id: switchTimeZoneButton
                Layout.preferredWidth: Math.max(changeRegionalSettingsButton.implicitWidth, switchTimeZoneButton.implicitWidth, appearancePage.comboBoxWidth)
                horizontalPadding: Qt.AlignLeft
                visible: KConfig.KAuthorized.authorizeControlModule("kcm_clock")
                text: i18nc("@action:button opens kcm", "Time Zone…")
                icon.name: "preferences-system-time"
                onClicked: KCMUtils.KCMLauncher.openSystemSettings("kcm_clock")
            }

            QQC2.Button {
                id: changeRegionalSettingsButton
                visible: KConfig.KAuthorized.authorizeControlModule("kcm_regionandlang")
                Layout.preferredWidth: Math.max(changeRegionalSettingsButton.implicitWidth, switchTimeZoneButton.implicitWidth, appearancePage.comboBoxWidth)
                text: i18nc("@action:button opens kcm", "Regional Settings…")
                icon.name: "preferences-desktop-locale"
                onClicked: KCMUtils.KCMLauncher.openSystemSettings("kcm_regionandlang")
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }



        RowLayout {
            Kirigami.FormData.label: i18n("Display time zone as:")
            Kirigami.FormData.buddyFor: displayTimeZoneFormat
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            enabled: appearancePage.cfg_informationDisplay !== 0

            QQC2.ComboBox {
                id: displayTimeZoneFormat

                Layout.preferredWidth: appearancePage.comboBoxWidth
                model: [
                    i18n("Code"),
                    i18n("City"),
                    i18n("Offset from UTC time"),
                ]
                onActivated: appearancePage.cfg_displayTimezoneFormat = currentIndex
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }


        
        RowLayout {
            Layout.fillWidth: true
            enabled: appearancePage.cfg_informationDisplay != 0
            Kirigami.FormData.label: i18nc("@label:listbox", "Time format:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.ComboBox {
                id: timeFormat
                Layout.preferredWidth: appearancePage.comboBoxWidth
                textRole: "label"
                model: [
                    {
                        label: i18nc("@item:inlistbox time display option", "Use region defaults"),
                        name: "timeRegional",
                         formatter(d) {
                            const format = timeFormatter.timeFormatCorrection(Qt.locale().timeFormat(Locale.ShortFormat), appearancePage.cfg_showSeconds === 2);
                            return Qt.formatTime(d, format);
                        }
                    },
                    {
                        label: i18nc("@item:inlistbox time display option", "12-Hour"),
                        name: "time12h",
                         formatter(d) {
                            let seconds = (appearancePage.cfg_showSeconds === 2) ? ":ss" : "";
                            let time = "hh:mm" + seconds + " ap";
                            return Qt.formatTime(d, time);
                        }
                    },
                    {
                        label: i18nc("@item:inlistbox time display option", "24-Hour"),
                        name: "time24h",
                         formatter(d) {
                            let seconds = (appearancePage.cfg_showSeconds === 2) ? ":ss" : "";
                            let time = "hh:mm" + seconds;
                            return Qt.formatTime(d, time);
                        }
                    },
                    {
                        label: i18nc("@item:inlistbox time display option", "Custom"),
                        name: "timeCustom",
                         formatter(d) {
                            return Qt.formatTime(d, customTimeFormat.text);
                        }
                    }
                    
                ]
                onActivated: appearancePage.cfg_timeFormat = model[currentIndex]["name"]

                Component.onCompleted: {
                    const isConfiguredTimeFormat = item => item["name"] === Plasmoid.configuration.timeFormat;
                    currentIndex = model.findIndex(isConfiguredTimeFormat);
                }
            }

            QQC2.Label {
                id: timeExampleLabel
                Layout.preferredWidth: Math.max(changeRegionalSettingsButton.implicitWidth, switchTimeZoneButton.implicitWidth)
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                textFormat: Text.PlainText
                text: timeFormat.model[timeFormat.currentIndex].formatter(new Date()) 
                QQC2.ToolTip.text: text
                QQC2.ToolTip.visible: (exampleHoverHandler2.hovered || activeFocus) && implicitWidth > width
                // no ToolTip.delay, this is an edge case and we might as well show it immediately if it applies

                HoverHandler {
                    id: exampleHoverHandler2
                }
            }
        }

        QQC2.TextField {
            id: customTimeFormat
            Layout.fillWidth: true
            enabled: appearancePage.cfg_informationDisplay != 0
            visible: appearancePage.cfg_timeFormat === "timeCustom"
        }

        QQC2.Label {
            text: i18n("<a href=\"https://doc.qt.io/qt-6/qml-qtqml-qt.html#formatDateTime-method\">Time Format Documentation</a>")
            enabled: appearancePage.cfg_informationDisplay != 0
            visible: appearancePage.cfg_timeFormat === "timeCustom"
            wrapMode: Text.Wrap

            Layout.preferredWidth: Layout.maximumWidth
            Layout.maximumWidth: Kirigami.Units.gridUnit * 16

            HoverHandler {
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : undefined
            }

            onLinkActivated: link => Qt.openUrlExternally(link)
        }
        

        Item {
            Kirigami.FormData.isSection: true
        }

        RowLayout {
            Kirigami.FormData.label: i18nc("@label:listbox", "Date format:")
            enabled: appearancePage.cfg_informationDisplay != 1
            spacing: Kirigami.Units.smallSpacing

            QQC2.ComboBox {
                id: dateFormat
                Layout.preferredWidth: appearancePage.comboBoxWidth
                textRole: "label"
                model: [
                    {
                        label: i18nc("@item:inlistbox date display option, includes e.g. day of week and month as word", "Long date"),
                        name: "longDate",
                        formatter(d) {
                            return Qt.formatDate(d, Qt.locale(), Locale.LongFormat);
                        },
                    },
                    {
                        label: i18nc("@item:inlistbox date display option, e.g. all numeric", "Short date"),
                        name: "shortDate",
                        formatter(d) {
                            return Qt.formatDate(d, Qt.locale(), Locale.ShortFormat);
                        },
                    },
                    {
                        label: i18nc("@item:inlistbox date display option, yyyy-mm-dd", "ISO date"),
                        name: "isoDate",
                        formatter(d) {
                            return Qt.formatDate(d, Qt.ISODate);
                        },
                    },
                    {
                        label: i18nc("@item:inlistbox custom date format", "Custom"),
                        name: "custom",
                        formatter(d) {
                            return Qt.locale().toString(d, customDateFormat.text);
                        },
                    },
                ]
                onActivated: appearancePage.cfg_dateFormat = model[currentIndex]["name"];

                Component.onCompleted: {
                    const isConfiguredDateFormat = item => item["name"] === Plasmoid.configuration.dateFormat;
                    currentIndex = model.findIndex(isConfiguredDateFormat);
                }
            }

            QQC2.Label {
                id: dateExampleLabel
                Layout.preferredWidth: Math.max(changeRegionalSettingsButton.implicitWidth, switchTimeZoneButton.implicitWidth)
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                textFormat: Text.PlainText
                text: dateFormat.model[dateFormat.currentIndex].formatter(new Date());
                QQC2.ToolTip.text: text
                QQC2.ToolTip.visible: (exampleHoverHandler.hovered || activeFocus) && implicitWidth > width
                // no ToolTip.delay, this is an edge case and we might as well show it immediately if it applies

                HoverHandler {
                    id: exampleHoverHandler
                }
            }
        }

        QQC2.TextField {
            id: customDateFormat
            Layout.fillWidth: true
            enabled: appearancePage.cfg_informationDisplay != 1
            visible: appearancePage.cfg_dateFormat === "custom"
        }

        QQC2.Label {
            text: i18n("<a href=\"https://doc.qt.io/qt-6/qml-qtqml-qt.html#formatDateTime-method\">Time Format Documentation</a>")
            enabled: appearancePage.cfg_informationDisplay != 1
            visible: appearancePage.cfg_dateFormat === "custom"
            wrapMode: Text.Wrap

            Layout.preferredWidth: Layout.maximumWidth
            Layout.maximumWidth: Kirigami.Units.gridUnit * 16

            HoverHandler {
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : undefined
            }

            onLinkActivated: link => Qt.openUrlExternally(link)
        }

        Item {
            Kirigami.FormData.isSection: true
            visible: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
        }

        QQC2.ButtonGroup {
            buttons: [alignLeft, alignCenter, alignRight]
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Text alignment:")
            spacing: Kirigami.Units.smallSpacing
            visible: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
            enabled: Plasmoid.formFactor === PlasmaCore.Types.Horizontal && appearancePage.cfg_informationDisplay == 2 &&
                (appearancePage.cfg_informationDisplayFormat == 0 || appearancePage.cfg_informationDisplayFormat == 1)

            QQC2.RadioButton {
                id: alignLeft
                text: i18n("Left")
                checked: appearancePage.cfg_textAlignment == 0
                onToggled: if (checked) appearancePage.cfg_textAlignment = 0 
                
            }

            QQC2.RadioButton {
                id: alignCenter
                text: i18n("Center")
                checked: appearancePage.cfg_textAlignment == 1
                onToggled: if (checked) appearancePage.cfg_textAlignment = 1
                
            }

            QQC2.RadioButton {
                id: alignRight
                text: i18n("Right")
                checked: appearancePage.cfg_textAlignment == 2
                onToggled: if (checked) appearancePage.cfg_textAlignment = 2
            }
        }


        Item {
            Kirigami.FormData.isSection: true
        }


        QQC2.ButtonGroup {
            buttons: [autoFontAndSizeRadioButton, manualFontAndSizeRadioButton]
        }

        ColumnLayout {
            spacing: Kirigami.Units.smallSpacing
            Kirigami.FormData.label: i18nc("@label:group", "Text display:")
            Kirigami.FormData.buddyFor: autoFontAndSizeRadioButton

            QQC2.RadioButton {
                id: autoFontAndSizeRadioButton
                text: i18nc("@option:radio", "Automatic")
            }

            QQC2.Label {
                text: i18nc("@label", "Text will follow the system font and expand to fill the available space.")
                Layout.leftMargin: autoFontAndSizeRadioButton.indicator.width + autoFontAndSizeRadioButton.spacing
                textFormat: Text.PlainText
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                font: Kirigami.Theme.smallFont
            }
        }

        RowLayout {
            spacing: Kirigami.Units.smallSpacing

            QQC2.RadioButton {
                id: manualFontAndSizeRadioButton
                text: i18nc("@option:radio setting for manually configuring the font settings", "Manual")
                checked: !appearancePage.cfg_autoFontAndSize
                onClicked: {
                    if (appearancePage.cfg_fontFamily === "") {
                        fontDialog.fontChosen = Kirigami.Theme.defaultFont
                    }
                }
            }

            QQC2.Button {
                text: i18nc("@action:button", "Choose Style…")
                icon.name: "settings-configure"
                enabled: manualFontAndSizeRadioButton.checked
                onClicked: {
                    fontDialog.currentFont = fontDialog.fontChosen
                    fontDialog.open()
                }
            }

        }

        ColumnLayout {
            spacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                visible: manualFontAndSizeRadioButton.checked
                Layout.leftMargin: manualFontAndSizeRadioButton.indicator.width + manualFontAndSizeRadioButton.spacing
                text: i18nc("@info %1 is the font size, %2 is the font family", "%1pt %2", cfg_fontSize, fontDialog.fontChosen.family)
                textFormat: Text.PlainText
                font: fontDialog.fontChosen
            }
            QQC2.Label {
                visible: manualFontAndSizeRadioButton.checked
                Layout.leftMargin: manualFontAndSizeRadioButton.indicator.width + manualFontAndSizeRadioButton.spacing
                text: i18nc("@info", "Note: size may be reduced if the panel is not thick enough.")
                textFormat: Text.PlainText
                font: Kirigami.Theme.smallFont
            }
        }
    }

    // Use the Qt.Labs font dialog so it looks okay, or else we get the half-baked
    // QML version shipped in Qt 6, which doesn't look good.
    // Port back to the standard QtDialogs version when one of the following happens:
    // Qt's QML font dialog implementation looks better
    // We override the default dialog with our own in plasma-integration
    Platform.FontDialog {
        id: fontDialog
        title: i18nc("@title:window", "Choose a Font")
        modality: Qt.WindowModal
        parentWindow: appearancePage.Window.window

        property font fontChosen: null

        onAccepted: {
            fontChosen = font
        }
    }

    Component.onCompleted: {
        if (!Plasmoid.configuration.showLocalTimeZone) {
            showLocalTimeZoneWhenDifferent.checked = true;
        }
    }
}
