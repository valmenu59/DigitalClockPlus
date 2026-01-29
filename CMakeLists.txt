cmake_minimum_required(VERSION 3.16)

project(DateV2)


set(PROJECT_VERSION "6.6.80")
string(REPLACE "." ";" VERSION_LIST ${PROJECT_VERSION})
list(GET VERSION_LIST 0 PROJECT_VERSION_MAJOR)
list(GET VERSION_LIST 1 PROJECT_VERSION_MINOR)
list(GET VERSION_LIST 2 PROJECT_VERSION_PATCH)

# Works on KDE 6.1 or +
set(PROJECT_DEP_VERSION "6.5.90")
set(QT_MIN_VERSION "6.6.0")
set(KF6_MIN_VERSION "6.0.0")

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
#include(CMakePackageConfigHelpers)
include(CheckIncludeFiles)
#include(FeatureSummary)
#include(KDEGitCommitHooks)
include(ECMFindQmlModule)
include(ECMGenerateQmlTypes)
include(ECMDeprecationSettings)
include(ECMQmlModule)



find_package(KF6 ${KF6_MIN_VERSION} REQUIRED COMPONENTS
                    #Archive Auth CoreAddons Crash
                    I18n IconThemes KIO
                    TextWidgets 
                    OPTIONAL_COMPONENTS DocTools)
find_package(Plasma ${PROJECT_DEP_VERSION} REQUIRED)



#if (BUILD_TESTING)
#    include(ECMAddTests)
#    find_package(Qt6 ${QT_MIN_VERSION} CONFIG REQUIRED COMPONENTS Test QuickTest)
 #   find_package(Qt6 REQUIRED CONFIG COMPONENTS WaylandCompositor)
#endif()




find_package(ICU COMPONENTS i18n uc)
set_package_properties(ICU
        PROPERTIES DESCRIPTION "Unicode and Globalization support for software applications"
        TYPE REQUIRED
        PURPOSE "Better application groups in Kicker, timezone support"
        )
if(ICU_FOUND)
    set(HAVE_ICU TRUE)
endif()



# Clipboard applet
ecm_find_qmlmodule(org.kde.prison 1.0)

# Is building in KDE CI
if(DEFINED ENV{KDECI_BUILD})
    set(KDECI_BUILD true)
endif()


include_directories("${CMAKE_CURRENT_BINARY_DIR}")

ecm_set_disabled_deprecation_versions(
    QT 5.15.2
    KF 5.98.0
)



# locate qdbus in the Qt path because not every distro makes a symlink at /usr/bin/qdbus
ecm_query_qt(QtBinariesDir QT_INSTALL_BINS)


if(KF6DocTools_FOUND)
  #add_subdirectory(doc)
  kdoctools_install(po)
endif()



add_subdirectory(plugin)

plasma_add_applet(com.clock.plus
    QML_SOURCES
        CalendarView.qml
        configAppearance.qml
        configCalendar.qml
        configTimeZones.qml
        DigitalClock.qml
        main.qml
        NoTimezoneWarning.qml
        Tooltip.qml
        config.qml
        TimeFormat.qml
    RESOURCES
        main.xml
    GENERATE_APPLET_CLASS
)