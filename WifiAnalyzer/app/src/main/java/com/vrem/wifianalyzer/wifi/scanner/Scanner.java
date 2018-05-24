/*
 *    Copyright (C) 2015 - 2016 VREM Software Development <VREMSoftwareDevelopment@gmail.com>
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package com.vrem.wifianalyzer.wifi.scanner;

import android.content.IntentFilter;
import android.net.wifi.WifiManager;
import android.os.Handler;
import android.support.annotation.NonNull;
import android.content.Context;
import android.os.Bundle;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import java.util.Calendar;
import com.vrem.wifianalyzer.MainActivity;
import com.vrem.wifianalyzer.MainContext;
import com.vrem.wifianalyzer.settings.Settings;
import com.vrem.wifianalyzer.wifi.model.WiFiData;
import com.vrem.wifianalyzer.wifi.model.WiFiDetail;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.app.Activity;
import android.os.Environment;
import android.provider.Settings.Secure;

import java.io.*;
import java.util.Map;
import java.util.TreeMap;

public class Scanner {
    private final Map<String, UpdateNotifier> updateNotifiers;
    private final WifiManager wifiManager;
    private final Transformer transformer;
    private Cache cache;
    private PeriodicScan periodicScan;
    private LocationManager locationManager;
    public String pos_lat;
    public String pos_long;
    private String phone_ID;


    public Scanner() {
        this.wifiManager = null;
        this.updateNotifiers = null;
        this.transformer = null;

    }

    public Scanner(@NonNull WifiManager wifiManager, @NonNull Handler handler, @NonNull Settings settings, @NonNull Transformer transformer) {
        this.wifiManager = wifiManager;
        this.updateNotifiers = new TreeMap<>();
        this.transformer = transformer;
        this.setCache(new Cache());
        this.periodicScan = new PeriodicScan(this, handler, settings);
        this.phone_ID =Secure.getString(MainContext.INSTANCE.getContext().getContentResolver(), Secure.ANDROID_ID);
    }


    public void update(String a, String b) {
        if (!wifiManager.isWifiEnabled()) {
            wifiManager.setWifiEnabled(true);
        }
        if (wifiManager.startScan()) {

            cache.add(wifiManager.getScanResults());
            WiFiData wiFiData = transformer.transformToWiFiData(cache.getScanResults(), wifiManager.getConnectionInfo(), wifiManager.getConfiguredNetworks());
            if (this.pos_long != null && this.pos_lat != null) {
                try {
                    File sdCard = Environment.getExternalStorageDirectory();
                    File directory = new File (sdCard.getAbsolutePath() +
                            "/WIFI");
                    if (!directory.exists())
                    {
                        directory.mkdirs();
                    }

                    File file = new File(directory, "scanresults_" + this.phone_ID + ".csv");
                    if (!file.exists())
                    {
                        file.createNewFile();
                    }
                    FileOutputStream fileinput = new FileOutputStream(file,true);
                    PrintStream printstream = new PrintStream(fileinput);
                     for (WiFiDetail wd :wiFiData.getWiFiDetails()) {
                            System.out.println(wd);
                            printstream.print(Calendar.getInstance().getTimeInMillis() + ";" +
                                        this.pos_lat + ";" + this.pos_long + ";" +
                                        wd.getBSSID() + ";" + wd.getSSID() + ";" +
                                        wd.getWiFiSignal().getLevel() + ";" +
                                        wd.getWiFiSignal().getFrequency() + ";" + wd.getWiFiSignal().getDistance() + ";" +
                                        wd.getCapabilities() + ";" + wd.getSecurity()
                            + "\n");
                            wd.getWiFiSignal().getDistance();
                    }
                    fileinput.close();
                } catch (IOException ioe) { }
            }
            for (String key : updateNotifiers.keySet()) {
                UpdateNotifier updateNotifier = updateNotifiers.get(key);
                updateNotifier.update(wiFiData);
            }
        }
    }

    public void addUpdateNotifier(@NonNull UpdateNotifier updateNotifier) {
        String key = updateNotifier.getClass().getName();
        updateNotifiers.put(key, updateNotifier);
    }

    public void pause() {
        periodicScan.stop();
    }

    public boolean isRunning() {
        return periodicScan.isRunning();
    }

    public void resume() {
        periodicScan.start();
    }

    protected PeriodicScan getPeriodicScan() {
        return periodicScan;
    }

    protected void setPeriodicScan(@NonNull PeriodicScan periodicScan) {
        this.periodicScan = periodicScan;
    }

    protected void setCache(@NonNull Cache cache) {
        this.cache = cache;
    }

    protected Map<String, UpdateNotifier> getUpdateNotifiers() {
        return updateNotifiers;
    }



}
