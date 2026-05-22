#import "Headers.h"

static BOOL _spoofEnabled = NO;
static BOOL _spoofCached = NO;

static BOOL getSpoofEnabled() {
    if (!_spoofCached) {
        _spoofEnabled = IS_ENABLED(SpoofWebSafari);
        _spoofCached = YES;
    }
    return _spoofEnabled;
}

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
        return YES;
    }
    return %orig;
}

%end

%ctor {
    %init;
    // Reset cache mỗi khi app foreground
    // để đọc lại preference mới nhất
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationWillEnterForegroundNotification
        object:nil
        queue:nil
        usingBlock:^(NSNotification *note) {
            _spoofCached = NO;
        }
    ];
}