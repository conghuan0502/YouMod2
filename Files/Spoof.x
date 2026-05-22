#import "Headers.h"

static BOOL _spoofCached = NO;
static BOOL _spoofEnabled = NO;

static BOOL getSpoofEnabled() {
    if (!_spoofCached) {
        _spoofEnabled = IS_ENABLED(SpoofWebSafari);
        _spoofCached = YES;
    }
    return _spoofEnabled;
}

// Thêm vào Spoof.x

%hook YTISabrClientConfig

- (BOOL)disableSABR {
    if (getSpoofEnabled()) {
        YouModLogInfo(@"YTISabrClientConfig: disableSABR → YES");
        return YES;
    }
    return %orig;
}

- (BOOL)isSabr {
    if (getSpoofEnabled()) {
        return NO;
    }
    return %orig;
}

%end

%hook MLPlatypusABRLoader

- (id)initWithQueue:(id)queue
playerItemEventCenter:(id)eventCenter
       playerConfig:(id)config
      QOEController:(id)qoe {
    YouModLogInfo(@"MLPlatypusABRLoader: intercepted init");
    id result = %orig;
    if (result && getSpoofEnabled()) {
        // Set _disableSABR ivar trực tiếp
        @try {
            [result setValue:@YES forKey:@"_disableSABR"];
            YouModLogInfo(@"MLPlatypusABRLoader: _disableSABR = YES");
        } @catch (NSException *e) {
            YouModLogError([NSString stringWithFormat:
                @"MLPlatypusABRLoader setValue error: %@", e.reason]);
        }
    }
    return result;
}

- (void)onQoeError:(id)fallbackConfig {
    YouModLogWarn(@"MLPlatypusABRLoader: QoE error triggered");
    %orig;
}

%end

%hook MLMediaDataLoader

- (id)initWithDataLoader:(id)dataLoader
                 config:(id)config
     firstRequestNumber:(long long)firstRequestNumber
                useUMP:(BOOL)useUMP
formatPacingBitrateCap:(double)bitrateCap
networkRequestObserver:(id)networkObserver
  hostFallbackObserver:(id)fallbackObserver {

    if (getSpoofEnabled() && useUMP) {
        YouModLogInfo(@"MLMediaDataLoader: useUMP forced NO");
        return %orig(dataLoader, config, firstRequestNumber,
                     NO, bitrateCap, networkObserver, fallbackObserver);
    }
    return %orig;
}

- (BOOL)shouldFallbackFromPrimaryURL:(id)primary
                       toFallbackURL:(id)fallback {
    if (getSpoofEnabled()) {
        YouModLogInfo(@"MLMediaDataLoader: forcing fallback YES");
        return YES;
    }
    return %orig;
}

- (void)task:(id)task didCompleteWithError:(id)error {
    if (error && IS_ENABLED(DebugMode)) {
        YouModLogError([NSString stringWithFormat:
            @"MLMediaDataLoader error: %@", error]);
    }
    %orig;
}

%end

// ✅ Hook HAM layer để tìm SABR class
%hook HAMDataLoader

- (id)init {
    YouModLogInfo(@"HAMDataLoader init");
    return %orig;
}

%end

%ctor {
    %init;
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationWillEnterForegroundNotification
        object:nil
        queue:nil
        usingBlock:^(NSNotification *note) {
            _spoofCached = NO;
        }
    ];
}