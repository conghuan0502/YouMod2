#import "Headers.h"

// Dùng %hook của Logos thay vì manual swizzle
// An toàn hơn, không risk infinite loop

%hook YTIClientInfo

- (NSString *)clientName {
    if (IS_ENABLED(SpoofWebSafari)) {
        YouModLogInfo(@"Spoof: clientName → WEB_SAFARI");
        return @"WEB_SAFARI";
    }
    return %orig;
}

- (NSString *)clientVersion {
    if (IS_ENABLED(SpoofClientVersion)) {
        YouModLogInfo(@"Spoof: clientVersion → 21.20.4");
        return @"21.20.4";
    }
    return %orig;
}

// Cần spoof thêm các field này để server không detect mismatch
- (NSString *)osName {
    if (IS_ENABLED(SpoofWebSafari)) {
        return @"Macintosh";
    }
    return %orig;
}

- (NSString *)platform {
    if (IS_ENABLED(SpoofWebSafari)) {
        return @"WEB";
    }
    return %orig;
}

- (int32_t)clientNameEnum {
    if (IS_ENABLED(SpoofWebSafari)) {
        return 7; // WEB_SAFARI = 7 trong Innertube enum
    }
    return %orig;
}

%end