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

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Handler;
import android.support.annotation.NonNull;

import com.vrem.wifianalyzer.settings.Settings;

public class PeriodicScan extends BroadcastReceiver implements Runnable {
    protected static final int DELAY_INITIAL = 1;
    protected static final int DELAY_INTERVAL = 1000;

    private final Scanner scanner;
    private final Handler handler;
    private final Settings settings;
    private boolean running;
    private String pos_lat;
    private String pos_long;

    public PeriodicScan() {
        this.scanner = null;
        this.handler = null;
        this.settings = null;
    }

    public PeriodicScan(@NonNull Scanner scanner, @NonNull Handler handler, @NonNull Settings settings) {
        this.scanner = scanner;
        this.handler = handler;
        this.settings = settings;
        start();
    }

    public void stop() {
        handler.removeCallbacks(this);
        running = false;
    }

    public void start() {
        nextRun(DELAY_INITIAL);
    }

    private void nextRun(int delayInitial) {
        stop();
        handler.postDelayed(this, delayInitial);
        running = true;
    }

    @Override
    public void run() {
        scanner.update(this.pos_lat,this.pos_long);
        nextRun(settings.getScanInterval() * DELAY_INTERVAL);
    }

    public boolean isRunning() {
        return running;
    }


    public void onReceive(Context context, Intent intent) {
        System.out.println("Received update");
       // this.pos_lat = Double.toString(intent.getDoubleExtra("lat",0.0));
        //this.pos_long =  Double.toString(intent.getDoubleExtra("long",0.0));
    }

}
