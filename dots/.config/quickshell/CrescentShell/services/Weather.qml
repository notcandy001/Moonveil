pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

import qs.modules

Singleton {
    id: root
    // 10 minute
    readonly property int fetchInterval: Config.options.bar.weather.fetchInterval * 60 * 1000
    readonly property string city: Config.options.bar.weather.city
    readonly property bool useUSCS: Config.options.bar.weather.useUSCS
    property bool gpsActive: false

    onUseUSCSChanged: {
        root.getData();
    }
    onCityChanged: {
        root.getData();
    }

    property var location: ({
        valid: false,
        lat: 0,
        lon: 0
    })

    property var data: ({
        uv: 0,
        humidity: 0,
        sunrise: 0,
        sunset: 0,
        windDir: 0,
        wCode: 0,
        city: 0,
        wind: 0,
        precip: 0,
        visib: 0,
        press: 0,
        temp: 0,
        tempFeelsLike: 0,
        lastRefresh: 0,
    })

    function refineData(data) {
        let temp = {};
        temp.uv = data?.current?.uvIndex || 0;
        temp.humidity = (data?.current?.humidity || 0) + "%";
        temp.sunrise = data?.astronomy?.sunrise || "0.0";
        temp.sunset = data?.astronomy?.sunset || "0.0";
        temp.windDir = data?.current?.winddir16Point || "N";
        temp.wCode = data?.current?.weatherCode || "113";
        temp.city = data?.location?.areaName[0]?.value || "City";
        temp.temp = "";
        temp.tempFeelsLike = "";
        if (root.useUSCS) {
            temp.wind = (data?.current?.windspeedMiles || 0) + " mph";
            temp.precip = (data?.current?.precipInches || 0) + " in";
            temp.visib = (data?.current?.visibilityMiles || 0) + " m";
            temp.press = (data?.current?.pressureInches || 0) + " psi";
            temp.temp += (data?.current?.temp_F || 0);
            temp.tempFeelsLike += (data?.current?.FeelsLikeF || 0);
            temp.temp += "°F";
            temp.tempFeelsLike += "°F";
        } else {
            temp.wind = (data?.current?.windspeedKmph || 0) + " km/h";
            temp.precip = (data?.current?.precipMM || 0) + " mm";
            temp.visib = (data?.current?.visibility || 0) + " km";
            temp.press = (data?.current?.pressure || 0) + " hPa";
            temp.temp += (data?.current?.temp_C || 0);
            temp.tempFeelsLike += (data?.current?.FeelsLikeC || 0);
            temp.temp += "°C";
            temp.tempFeelsLike += "°C";
        }
        temp.lastRefresh = DateTime.time + " • " + DateTime.date;
        root.data = temp;
    }

    function getData() {
        let command = "curl -s wttr.in";

        if (root.gpsActive && root.location.valid) {
            command += `/${root.location.lat},${root.location.long}`;
        } else {
            command += `/${formatCityName(root.city)}`;
        }

        // format as json
        command += "?format=j1";
        command += " | ";
        // only take the current weather, location, asytronmy data
        command += "jq '{current: .current_condition[0], location: .nearest_area[0], astronomy: .weather[0].astronomy[0]}'";
        fetcher.command[2] = command;
        fetcher.running = true;
    }

    function formatCityName(cityName) {
        return cityName.trim().split(/\s+/).join('+');
    }

    Component.onCompleted: {
        if (!root.gpsActive) return;
        console.info("[WeatherService] Starting the GPS service.");
        positionSource.start();
    }

    Process {
        id: fetcher
        command: ["bash", "-c", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0)
                    return;
                try {
                    const parsedData = JSON.parse(text);
                    root.refineData(parsedData);
                    // console.info(`[ data: ${JSON.stringify(parsedData)}`);
                } catch (e) {
                    console.error(`[WeatherService] ${e.message}`);
                }
            }
        }
    }


    Timer {
        running: !root.gpsActive
        repeat: true
        interval: root.fetchInterval
        triggeredOnStart: !root.gpsActive
        onTriggered: root.getData()
    }
}
