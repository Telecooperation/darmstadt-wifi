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

package com.vrem.wifianalyzer.wifi.band;

import android.support.annotation.NonNull;
import android.support.v4.util.Pair;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Locale;

class WiFiChannelsGHZ2 extends WiFiChannels {
    private final static Pair<Integer, Integer> RANGE = new Pair<>(2400, 2499);
    private final static List<Pair<WiFiChannel, WiFiChannel>> SETS = Arrays.asList(
        new Pair<>(new WiFiChannel(1, 2412), new WiFiChannel(13, 2472)),
        new Pair<>(new WiFiChannel(14, 2484), new WiFiChannel(14, 2484)));
    private final static Pair<WiFiChannel, WiFiChannel> SET = new Pair<>(SETS.get(0).first, SETS.get(SETS.size()-1).second);
    private final static int FREQUENCY_OFFSET = WiFiChannel.FREQUENCY_SPREAD * 2;
    private final static int FREQUENCY_SPREAD = WiFiChannel.FREQUENCY_SPREAD;

    WiFiChannelsGHZ2() {
        super(RANGE, SETS, FREQUENCY_OFFSET, FREQUENCY_SPREAD);
    }

    @Override
    public List<Pair<WiFiChannel, WiFiChannel>> getWiFiChannelPairs(@NonNull Locale locale) {
        return Collections.unmodifiableList(Arrays.asList(SET));
    }

    @Override
    public List<WiFiChannel> getAvailableChannels(@NonNull Locale locale) {
        List<WiFiChannel> wiFiChannels = new ArrayList<>();
        for (int channel : WiFiChannelCountry.find(locale.getCountry()).getChannelsGHZ2()) {
            wiFiChannels.add(getWiFiChannelByChannel(channel));
        }
        return wiFiChannels;
    }

    @Override
    public boolean isChannelAvailable(@NonNull Locale locale, int channel) {
        return WiFiChannelCountry.find(locale.getCountry()).isChannelAvailableGHZ2(channel);
    }

    @Override
    public WiFiChannel getWiFiChannelByFrequency(int frequency, @NonNull Pair<WiFiChannel, WiFiChannel> wiFiChannelPair) {
        return isInRange(frequency) ? getWiFiChannel(frequency, SET) : WiFiChannel.UNKNOWN;
    }

}

