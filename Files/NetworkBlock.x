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
    NSString *host = request.URL.host.lowercaseString;
    
    // Log tất cả googlevideo requests
    if (IS_ENABLED(DebugMode) && 
        [host containsString:@"googlevideo"]) {
        YouModLogInfo([NSString stringWithFormat:
            @"🎬 GOOGLEVIDEO: %@ %@", 
            request.HTTPMethod,
            request.URL.absoluteString.length > 100 ?
            [request.URL.absoluteString substringToIndex:100] : 
            request.URL.absoluteString]);
    }
    
    if (!IS_ENABLED(BlockDomains)) return NO;
    for (NSString *domain in blockedDomains) {
        if ([host containsString:domain]) {
            YouModLogWarn([NSString stringWithFormat:
                @"🛑 BLOCKED: %@", host]);
            return YES;
        }
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
