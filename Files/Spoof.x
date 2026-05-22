#import "Headers.h"

// Dùng flag tĩnh để tránh gọi NSUserDefaults trong hot path
static BOOL _spoofEnabled = NO;

%hook MLMediaDataLoader

- (id)initWithDataLoader:(id)dataLoader
                 config:(id)config
     firstRequestNumber:(long long)firstRequestNumber
                useUMP:(BOOL)useUMP
formatPacingBitrateCap:(double)bitrateCap
networkRequestObserver:(id)networkObserver
  hostFallbackObserver:(id)fallbackObserver {

    // Đọc preference 1 lần, cache lại
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _spoofEnabled = IS_ENABLED(SpoofWebSafari);
    });

    if (_spoofEnabled && useUMP) {
        return %orig(dataLoader, config, firstRequestNumber,
                     NO, bitrateCap, networkObserver, fallbackObserver);
    }
    return %orig;
}

%end

%ctor {
    %init;
    // Reset cache khi preference thay đổi
    CFNotificationCenterAddObserver(
        CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        (CFNotificationCallback)^(CFNotificationCenterRef c, void *o, 
                                   CFStringRef n, const void *obj, 
                                   CFDictionaryRef u) {
            _spoofEnabled = IS_ENABLED(SpoofWebSafari);
        },
        CFSTR("com.apple.preferences.changed"),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately
    );
}