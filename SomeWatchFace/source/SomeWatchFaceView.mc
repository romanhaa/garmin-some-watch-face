import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Weather;

class SomeWatchFaceView extends WatchUi.WatchFace {

    const MINUTE = 60;
    const HOUR = self.MINUTE * 60;

    const intervalUpdateFeelsLikeTemp = self.HOUR;
    var lastUpdatedFeelsLikeTemp;

    const intervalUpdateDailyLowHighTemp = self.HOUR * 4;
    var lastUpdatedDailyLowHighTemp;

    const intervalUpdateSteps = 60;
    var lastUpdatedSteps;

    const intervalUpdateActiveMinutes = 60;
    var lastUpdatedActiveMinutes;

    const intervalUpdateCurrentHeartRate = 15;
    var lastUpdatedCurrentHeartRate;

    var nextUpdateSunriseSunset;

    const intervalUpdateBattery = 60;
    var lastUpdatedBattery;

    // TODO Update at specific time (like sunrise/sunset).
    const intervalUpdateDate = 60;
    var lastUpdatedDate;

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {

        var nowAsMoment = new Time.Moment(Time.now().value());
        // System.println(nowAsMoment.value());

        // Get and show the current time
        // NOTE Time updates every second even though only hours and minutes are
        //      shown.
        var clockTime = System.getClockTime();
        var timeString = Lang.format("$1$:$2$", [clockTime.hour, clockTime.min.format("%02d")]);
        // var timeString = Lang.format("$1$:$2$:$3$", [clockTime.hour, clockTime.min.format("%02d"), clockTime.sec.format("%02d")]);
        var viewTime = View.findDrawableById("TimeLabel") as Text;
        viewTime.setText(timeString);

        // Update date.
        if (self.shouldUpdate(nowAsMoment, lastUpdatedDate, intervalUpdateDate)) {
            // System.println("setting date because reference time was null or because it's time to do so");
            self.updateDate(clockTime, nowAsMoment);
        }

        // Update feels like temperature.
        if (self.shouldUpdate(nowAsMoment, lastUpdatedFeelsLikeTemp, intervalUpdateFeelsLikeTemp)) {
            // System.println("setting feels like temp because reference time was null or because it's time to do so");
            self.updateFeelsLikeTemp(clockTime, nowAsMoment);
        }

        // Update daily low/high temperature.
        if (self.shouldUpdate(nowAsMoment, lastUpdatedDailyLowHighTemp, intervalUpdateDailyLowHighTemp)) {
            // System.println("setting daily low/high temp because reference time was null or because it's time to do so");
            self.updateDailyLowHighTemp(clockTime, nowAsMoment);
        }

        // Update (daily) step count.
        if (self.shouldUpdate(nowAsMoment, lastUpdatedSteps, intervalUpdateSteps)) {
            // System.println("setting steps because reference time was null or because it's time to do so");
            self.updateSteps(clockTime, nowAsMoment);
        }

        // Update (weekly) active minutes.
        if (self.shouldUpdate(nowAsMoment, lastUpdatedActiveMinutes, intervalUpdateActiveMinutes)) {
            // System.println("setting active minutes because reference time was null or because it's time to do so");
            self.updateActiveMinutes(clockTime, nowAsMoment);
        }

        // Update current heart rate.
        if (self.shouldUpdate(nowAsMoment, lastUpdatedCurrentHeartRate, intervalUpdateCurrentHeartRate)) {
            // System.println("setting current heart rate because reference time was null or because it's time to do so");
            self.updateCurrentHeartRate(clockTime, nowAsMoment);
        }

        // Update sunrise and sunset.
        if (nextUpdateSunriseSunset == null || nowAsMoment.greaterThan(nextUpdateSunriseSunset)) {
            // System.println("setting sunrise/sunset because reference time was null or because it's time to do so");
            self.updateSunriseSunset(clockTime, nowAsMoment);
        }

        // Update battery.
        if (self.shouldUpdate(nowAsMoment, lastUpdatedBattery, intervalUpdateBattery)) {
            // System.println("setting battery because reference time was null or because it's time to do so");
            self.updateBattery(clockTime, nowAsMoment);
        }

        // Manage content of last row.
        var deviceSettings = System.getDeviceSettings();
        var numberOfAlarms = deviceSettings.alarmCount;
        var doNotDisturb = deviceSettings.doNotDisturb;
        var batteryLabel = View.findDrawableById("BatteryLabel") as Text;
        var singleIcon = View.findDrawableById("SingleIcon") as Text;
        var doubleIcon1 = View.findDrawableById("DoubleIcon1") as Text;
        var doubleIcon2 = View.findDrawableById("DoubleIcon2") as Text;
        if (numberOfAlarms >= 1 && doNotDisturb) {
            batteryLabel.setJustification(Graphics.TEXT_JUSTIFY_RIGHT);
            singleIcon.setText("");
            doubleIcon1.setText("R");
            doubleIcon2.setText("c");
        } else if (numberOfAlarms >= 1 && !doNotDisturb) {
            batteryLabel.setJustification(Graphics.TEXT_JUSTIFY_RIGHT);
            singleIcon.setText("R");
            doubleIcon1.setText("");
            doubleIcon2.setText("");
        } else if (numberOfAlarms == 0 && doNotDisturb) {
            batteryLabel.setJustification(Graphics.TEXT_JUSTIFY_RIGHT);
            singleIcon.setText("c");
            doubleIcon1.setText("");
            doubleIcon2.setText("");
        } else {
            batteryLabel.setJustification(Graphics.TEXT_JUSTIFY_CENTER);
            singleIcon.setText("");
            doubleIcon1.setText("");
            doubleIcon2.setText("");
        }

        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

    //
    function shouldUpdate(
        now as Time.Moment,
        lastUpdated as Time.Moment,
        updateInterval as Lang.Number
    ) {
        if (
            lastUpdated == null
            || now.subtract(lastUpdated).value() >= updateInterval
        ) {
            return true;
        } else {
            return false;
        }
    }

    function updateFeelsLikeTemp(clockTime as ClockTime, now as Time.Moment) as Void {
        var viewFeelsLikeTemp = View.findDrawableById("FeelsLikeTempLabel") as Text;
        var forecast = Weather.getCurrentConditions();
        if (forecast == null) {
            viewFeelsLikeTemp.setText("--");
            self.lastUpdatedFeelsLikeTemp = new Time.Moment(Time.now().value());
            return;
        }
        var temperature = forecast.feelsLikeTemperature;
        if (temperature == null) {
            viewFeelsLikeTemp.setText("--");
        } else {
            var temperatureString = Lang.format("$1$°", [temperature]);
            viewFeelsLikeTemp.setText(temperatureString);
        }

        // var lastUpdatedLabel = View.findDrawableById("FeelsLikeTempLastUpdatedLabel") as Text;
        // lastUpdatedLabel.setText(Lang.format("$1$:$2$:$3$", [clockTime.hour, clockTime.min.format("%02d"), clockTime.sec.format("%02d")]));

        self.lastUpdatedFeelsLikeTemp = new Time.Moment(Time.now().value());
    }

    function updateDailyLowHighTemp(clockTime as ClockTime, now as Time.Moment) as Void {
        var viewLabel = View.findDrawableById("DailyLowHighTempLabel") as Text;
        var dailyForecast = Weather.getDailyForecast();
        if (dailyForecast != null) {
            var dailyLowTemp = dailyForecast[0].lowTemperature;
            var dailyHighTemp = dailyForecast[0].highTemperature;
            if (dailyLowTemp != null && dailyHighTemp != null) {
                var dataString = Lang.format("$1$°|$2$°", [dailyLowTemp, dailyHighTemp]);
                viewLabel.setText(dataString);
            } else {
                viewLabel.setText("no temp");
            }
        } else {
            viewLabel.setText("no temp");
        }

        // var lastUpdatedLabel = View.findDrawableById("DailyLowHighTempLastUpdatedLabel") as Text;
        // lastUpdatedLabel.setText(Lang.format("$1$:$2$:$3$", [clockTime.hour, clockTime.min.format("%02d"), clockTime.sec.format("%02d")]));

        self.lastUpdatedDailyLowHighTemp = now;
    }

    function updateSteps(clockTime as ClockTime, now as Time.Moment) as Void {
        var viewLabel = View.findDrawableById("StepsLabel") as Text;
        viewLabel.setText(Lang.format("$1$", [ActivityMonitor.getInfo().steps]));

        // var lastUpdatedLabel = View.findDrawableById("StepsLastUpdatedLabel") as Text;
        // lastUpdatedLabel.setText(Lang.format("$1$:$2$:$3$", [clockTime.hour, clockTime.min.format("%02d"), clockTime.sec.format("%02d")]));

        self.lastUpdatedSteps = now;
    }

    function updateActiveMinutes(clockTime as ClockTime, now as Time.Moment) {
        var string = Lang.format("$1$", [ActivityMonitor.getInfo().activeMinutesWeek.total]);
        var viewLabel = View.findDrawableById("ActiveMinutesLabel") as Text;
        viewLabel.setText(string);

        // var lastUpdatedLabel = View.findDrawableById("ActiveMinutesLastUpdatedLabel") as Text;
        // lastUpdatedLabel.setText(Lang.format("$1$:$2$:$3$", [clockTime.hour, clockTime.min.format("%02d"), clockTime.sec.format("%02d")]));

        self.lastUpdatedActiveMinutes = now;
    }

    function updateCurrentHeartRate(clockTime as ClockTime, now as Time.Moment) as Void {
        // var currentHeartRateString = Lang.format("$1$", [Activity.getActivityInfo().currentHeartRate]);
        var heartRate = Activity.getActivityInfo().currentHeartRate;
        // var HRH = ActivityMonitor.getHeartRateHistory(1, true);
        // var HRS = HRH.next();
        // if (
        //     HRS != null
        //     && HRS.heartRate != ActivityMonitor.INVALID_HR_SAMPLE
        // ) {
        //     heartRate = HRS.heartRate;
        // }
        var viewLabel = View.findDrawableById("CurrentHeartRateLabel") as Text;
        if (heartRate == null) {
            viewLabel.setText("--");
        } else {
            var string = Lang.format("$1$", [heartRate]);
            viewLabel.setText(string);
        }

        // var lastUpdatedLabel = View.findDrawableById("CurrentHeartRateLastUpdatedLabel") as Text;
        // lastUpdatedLabel.setText(Lang.format("$1$:$2$:$3$", [clockTime.hour, clockTime.min.format("%02d"), clockTime.sec.format("%02d")]));

        self.lastUpdatedCurrentHeartRate = now;
    }

    function updateSunriseSunset(clockTime as ClockTime, now as Time.Moment) as Void {
        var viewLabel = View.findDrawableById("SunriseSunsetLabel") as Text;
        var currentConditions = Weather.getCurrentConditions();
        if (currentConditions == null) {
            viewLabel.setText("--");
            return;
        }
        var location = currentConditions.observationLocationPosition;
        var today = new Time.Moment(Time.today().value());
        if (location == null || today == null) {
            viewLabel.setText("--");
            return;
        }
        var sunrise = Weather.getSunrise(location, today);
        var sunset = Weather.getSunset(location, today);
        var string = "-";
        if (sunrise == null || sunset == null) {
            viewLabel.setText("--");
            return;
        }
        var info;
        if (now.lessThan(sunrise)) {
            info = Time.Gregorian.info(sunrise, Time.FORMAT_SHORT);
            // System.println("next event: sunrise");
            nextUpdateSunriseSunset = sunrise;
        } else if (now.greaterThan(sunrise) && now.lessThan(sunset)) {
            info = Time.Gregorian.info(sunset, Time.FORMAT_SHORT);
            // System.println("next event: sunset");
            nextUpdateSunriseSunset = sunset;
        } else {
            info = Time.Gregorian.info(sunrise, Time.FORMAT_SHORT);
            // System.println("next event: sunrise (tomorrow)");
            var oneDay = new Time.Duration(Gregorian.SECONDS_PER_DAY);
            var tomorrow = today.add(oneDay);
            nextUpdateSunriseSunset = Weather.getSunrise(location, tomorrow);
        }
        string = Lang.format("$1$:$2$", [
            info.hour.format("%01u"),
            info.min.format("%02u")
        ]);
        viewLabel.setText(string);
        // var lastUpdatedLabel = View.findDrawableById("SunriseSunsetLastUpdatedLabel") as Text;
        // lastUpdatedLabel.setText(Lang.format("$1$:$2$:$3$", [clockTime.hour, clockTime.min.format("%02d"), clockTime.sec.format("%02d")]));
        // self.lastUpdatedSunriseSunset = now;
    }

    function updateBattery(clockTime as ClockTime, now as Time.Moment) as Void {
        var string = Lang.format("$1$%", [System.getSystemStats().battery.toNumber()]);
        var view = View.findDrawableById("BatteryLabel") as Text;
        view.setText(string);

        self.lastUpdatedBattery = now;
    }

    function updateDate(clockTime as ClockTime, now as Time.Moment) as Void {
        var info = Time.Gregorian.info(now, Time.FORMAT_LONG);
        var string = Lang.format("$1$ $2$ $3$", [info.day, info.month, info.year]);
        var view = View.findDrawableById("DateLabel") as Text;
        view.setText(string);

        self.lastUpdatedDate = now;
    }

}
