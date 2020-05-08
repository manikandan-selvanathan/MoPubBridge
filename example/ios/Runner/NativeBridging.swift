//
//  NativeBridging.swift
//  Runner
//
//  Created by Kamran Pirwani on 3/21/20.
//  Copyright © 2020 The Chromium Authors. All rights reserved.
//

import Foundation
import Flutter

private enum BridgeEvent: String {
    case methodChannel = "com.firekamp.mopub/method"
    case rewardStream = "com.firekamp.mopub/reward_stream"
    case interstitialStream = "com.firekamp.mopub/interstitial_stream"
}

private enum BridgeMethods: String {
    case configure = "configure"
    case fetchAndLoadBanner = "fetchAndLoadBanner"
    case hideBanner = "hideBanner"
    case showBanner = "showBanner"
    case prefetchInterstitial = "prefetchInterstitial"
    case prefetchReward = "prefetchReward"
    case showInterstitialAd = "showInterstitialAd"
    case showRewardAd = "showRewardAd"
    case resumeBannerRefresh = "resumeBannerRefresh"
    case stopBannerRefresh = "stopBannerRefresh"
}

public class NativeBridging {
    private let supportedMethods = [BridgeMethods.configure.rawValue,
                                   BridgeMethods.fetchAndLoadBanner.rawValue,
                                    BridgeMethods.showBanner.rawValue,
                                    BridgeMethods.hideBanner.rawValue,
                                    BridgeMethods.prefetchInterstitial.rawValue,
                                    BridgeMethods.prefetchReward.rawValue,
                                    BridgeMethods.showInterstitialAd.rawValue,
                                    BridgeMethods.showRewardAd.rawValue,
                                    BridgeMethods.resumeBannerRefresh.rawValue,
                                    BridgeMethods.stopBannerRefresh.rawValue]
    
    private let methodChannel: FlutterMethodChannel
    private let interstitialChannel: FlutterEventChannel
    private let interstitialStreamHandler: AdStreamHandler
    
    private let rewardChannel: FlutterEventChannel
    private let rewardStreamHandler: AdStreamHandler

    private let adManager: AdManager
    
    init(binaryMessenger: FlutterBinaryMessenger, adManager: AdManager) {
        self.methodChannel = FlutterMethodChannel(name: BridgeEvent.methodChannel.rawValue, binaryMessenger: binaryMessenger)
        
        self.interstitialChannel = FlutterEventChannel(name: BridgeEvent.interstitialStream.rawValue, binaryMessenger: binaryMessenger)
        self.interstitialStreamHandler = AdStreamHandler()
        self.interstitialChannel.setStreamHandler(self.interstitialStreamHandler)
        
        self.rewardChannel = FlutterEventChannel(name: BridgeEvent.rewardStream.rawValue, binaryMessenger: binaryMessenger)
        self.rewardStreamHandler = AdStreamHandler()
        self.rewardChannel.setStreamHandler(self.rewardStreamHandler)
        
        self.adManager = adManager
        
        self.methodChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            self?.handleInvocation(call: call, result: result)
        })
        
        adManager.interstitialStream = { [weak self] (status) in
            self?.interstitialStreamHandler.emitEvent(status: status.rawValue)
        }
        
        adManager.rewardStream = { [weak self] (status) in
            self?.rewardStreamHandler.emitEvent(status: status.rawValue)
        }
    }
    
    func handleInvocation(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let methodCall = call.method
        
        guard supportedMethods.contains(methodCall) else {
            result(FlutterMethodNotImplemented)
            return
        }
        
        if methodCall == BridgeMethods.configure.rawValue {
            let adConfiguration=configure(call)
            if let adconfig=adConfiguration{
              adManager.configure(adconfig)
            }
            result(nil)
        }
        else if methodCall == BridgeMethods.fetchAndLoadBanner.rawValue {
            adManager.fetchAndLoadBanner()
            result(nil)
        }else if methodCall == BridgeMethods.showBanner.rawValue {
            adManager.showBannerAd()
            result(nil)
        } else if methodCall == BridgeMethods.hideBanner.rawValue {
            adManager.hideBannerAd()
            result(nil)
        } else if methodCall == BridgeMethods.prefetchInterstitial.rawValue {
            adManager.prefetchInterstitial()
            result(nil)
        } else if methodCall == BridgeMethods.prefetchReward.rawValue {
            adManager.prefetchReward()
            result(nil)
        } else if methodCall == BridgeMethods.showInterstitialAd.rawValue {
            adManager.showInterstitialAd()
            result(nil)
        } else if methodCall == BridgeMethods.showRewardAd.rawValue {
            adManager.showRewardAd()
            result(nil)
        } 
    }

    func configure(_ call:FlutterMethodCall) -> AdConfiguration?{
        var adConfiguration : AdConfiguration?
        guard let arguments: String = call.arguments as? String else {
            assert(false, "Arguments are empty")
            return nil
        }
    
        let data = arguments.data(using: .utf8)
        do {
            if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] {
                let bannerId: String? = json["bannerAdId"] as? String
                
                let interstitialAdId: String? = json["interstitialAdId"] as? String
                
                let rewardAdId: String? = json["rewardAdId"] as? String
                 
                let vungleAppId: String? = json["vungleAppId"] as? String
                
                let ironSourceApplicationKey: String? = json["ironSourceApplicationKey"] as? String
                
                let appLovinSdkKey: String? = json["appLovinSdkKey"] as? String
                
                let adColonyAppId: String? = json["adColonyAppId"] as? String
                
                let adColonyBannerZoneId: String? = json["adColonyBannerZoneId"] as? String
                
                let adColonyInterstitialZoneId: String? = json["adColonyInterstitialZoneId"] as? String
                
                let adColonyRewardedZoneId: String? = json["adColonyRewardedZoneId"] as? String
                
                let unityGameId: String? = json["unityGameId"] as? String
                
                let isFacebookEnabled: Bool = json["facebookEnabled"] as? Bool ?? false
                
                adConfiguration = AdConfiguration(moPubBannerId: bannerId, moPubInterstitialId: interstitialAdId, moPubRewardId: rewardAdId, adColonyAppId: adColonyAppId, adColonyBannerZoneId: adColonyBannerZoneId, adColonyInterstitialZoneId: adColonyInterstitialZoneId, adColonyRewardedZoneId: adColonyRewardedZoneId, vungleAppId: vungleAppId, ironSourceApplicationKey: ironSourceApplicationKey, appLovinSdkKey: appLovinSdkKey, unityGameId: unityGameId, isFacebookEnabled:isFacebookEnabled)
               }
        } catch let error as NSError {
            print(error)
        }
        return adConfiguration
    }
}



public class AdStreamHandler: NSObject, FlutterStreamHandler {
    
    private var _eventSink: FlutterEventSink?

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        _eventSink = events
              return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        _eventSink = nil
        return nil
    }
    
    func emitEvent(status: Int) {
        _eventSink?(status)
    }
    
}

