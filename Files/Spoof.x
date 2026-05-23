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

// ✅ Hook MLMediaDataLoader — force useUMP = NO
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

// ✅ Hook MLPlatypusABRLoader — disable SABR
%hook MLPlatypusABRLoader

- (void)setDelegate:(id)delegate {
    %orig;
    if (getSpoofEnabled()) {
        @try {
            [(NSObject *)self setValue:@YES forKey:@"_disableSABR"];
            YouModLogInfo(@"MLPlatypusABRLoader: _disableSABR=YES");
        } @catch (NSException *e) {
            YouModLogError([NSString stringWithFormat:
                @"MLPlatypusABRLoader setValue error: %@", e.reason]);
        }
    }
}

- (void)onQoeError:(id)config {
    YouModLogWarn(@"MLPlatypusABRLoader: QoE error triggered");
    %orig;
}

%end

// ✅ Hook YTISabrClientConfig — disable SABR từ config
%hook YTISabrClientConfig

- (BOOL)isSabr {
    if (getSpoofEnabled()) {
        return NO;
    }
    return %orig;
}

- (BOOL)disableSABR {
    if (getSpoofEnabled()) {
        YouModLogInfo(@"YTISabrClientConfig: disableSABR → YES");
        return YES;
    }
    return %orig;
}

%end

%hook YTIHeartbeatResponse

- (BOOL)hasHeartbeatToken { 
    return IS_ENABLED(SpoofWebSafari) ? YES : %orig; 
}

- (NSString *)heartbeatToken {
    return IS_ENABLED(SpoofWebSafari) ? @"" : %orig;
}

%end

// Và hook YTHeartbeatController
%hook YTHeartbeatController

- (void)heartbeatDidFail:(id)error {
    if (IS_ENABLED(SpoofWebSafari)) {
        YouModLogWarn(@"YTHeartbeatController: suppressed fail");
        return; // Không báo lỗi cho player
    }
    %orig;
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