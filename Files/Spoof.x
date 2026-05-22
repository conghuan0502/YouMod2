#import "Headers.h"

%hook MLMediaDataLoader

- (id)initWithDataLoader:(id)dataLoader
                 config:(id)config
     firstRequestNumber:(long long)firstRequestNumber
                useUMP:(BOOL)useUMP
formatPacingBitrateCap:(double)bitrateCap
networkRequestObserver:(id)networkObserver
  hostFallbackObserver:(id)fallbackObserver {
    
    if (IS_ENABLED(SpoofWebSafari)) {
        YouModLogInfo([NSString stringWithFormat:
            @"MLMediaDataLoader init: useUMP was %d → forcing NO", 
            useUMP]);
        return %orig(dataLoader, config, firstRequestNumber,
                     NO, bitrateCap, networkObserver, fallbackObserver);
    }
    return %orig;
}

// Log để debug xem có được gọi không
- (void)task:(id)task didCompleteWithError:(id)error {
    if (error && IS_ENABLED(DebugMode)) {
        YouModLogError([NSString stringWithFormat:
            @"MLMediaDataLoader error: %@", error]);
    }
    %orig;
}

- (BOOL)shouldFallbackFromPrimaryURL:(id)primary 
                        toFallbackURL:(id)fallback {
    if (IS_ENABLED(SpoofWebSafari)) {
        YouModLogInfo(@"MLMediaDataLoader: forcing fallback YES");
        return YES;
    }
    return %orig;
}

%end