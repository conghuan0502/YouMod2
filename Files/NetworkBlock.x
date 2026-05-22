#import "Headers.h"

@interface _YouModBlockedURLProtocol : NSURLProtocol
@end

static NSArray *blockedDomains;

@implementation _YouModBlockedURLProtocol

+ (void)initialize {
    if (self == [_YouModBlockedURLProtocol class]) {
        blockedDomains = @[
            @"iosantiabuse.googleapis.com", 
            @"play.googleapis.com",
            @"clients3.googleapis.com",
            @"s.youtube.com"
        ];
    }
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if (!IS_ENABLED(NetworkLogging)) return NO;
    NSString *url = request.URL.absoluteString;
    // Log videoplayback requests
    if ([url containsString:@"videoplayback"]) {
        YouModLogInfo([NSString stringWithFormat:
            @"🎬 VIDEOPLAYBACK: %@", 
            request.URL.query ? [request.URL.query substringToIndex:
                MIN(200, request.URL.query.length)] : @"no query"]);
    }
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotFindHost userInfo:@{NSLocalizedDescriptionKey: @"Blocked by YouMod"}];
    [self.client URLProtocol:self didFailWithError:error];
}

- (void)stopLoading {}

@end

%ctor {
    [NSURLProtocol registerClass:[_YouModBlockedURLProtocol class]];
}
