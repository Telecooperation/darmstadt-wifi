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

package com.vrem.wifianalyzer;

import android.support.annotation.NonNull;
import android.support.v4.util.Pair;

import com.vrem.wifianalyzer.wifi.band.WiFiChannel;

import java.util.Locale;

public class Configuration {
    private final Locale locale;
    private final boolean developmentMode;
    private final boolean largeScreenLayout;
    private Pair<WiFiChannel, WiFiChannel> wiFiChannelPair;

    public Configuration(@NonNull Locale locale, boolean largeScreenLayout, @NonNull Pair<WiFiChannel, WiFiChannel> wiFiChannelPair, boolean developmentMode) {
        this.locale = locale;
        this.largeScreenLayout = largeScreenLayout;
        setWiFiChannelPair(wiFiChannelPair);
        this.developmentMode = developmentMode;
    }

    public Locale getLocale() {
        return locale;
    }

    public boolean isLargeScreenLayout() {
        return largeScreenLayout;
    }

    public Pair<WiFiChannel, WiFiChannel> getWiFiChannelPair() {
        return wiFiChannelPair;
    }

    public void setWiFiChannelPair(@NonNull Pair<WiFiChannel, WiFiChannel> wiFiChannelPair) {
        this.wiFiChannelPair = wiFiChannelPair;
    }

    public boolean isDevelopmentMode() {
        return developmentMode;
    }
}
