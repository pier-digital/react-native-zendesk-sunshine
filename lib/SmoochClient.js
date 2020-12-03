'use strict';

import React from 'react';
import { NativeEventEmitter, Platform, NativeModules, DeviceEventEmitter } from 'react-native';

const { SmoochManager } = NativeModules;

const SmoochManagerEmitter = Platform.select({
    ios: new NativeEventEmitter(SmoochManager),
    android: DeviceEventEmitter,
  });

export {SmoochManager as Smooch, SmoochManagerEmitter};
