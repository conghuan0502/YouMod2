#import "Headers.h"
#import <objc/message.h>

static void SpoofSwizzleMethod(Class cls, SEL sel, id block) {
    Method m = class_getInstanceMethod(cls, sel);
    if (!m) {
        id dummy = ((id(*)(id, SEL))objc_msgSend)((id)cls, sel_registerName("alloc"));
        dummy = ((id(*)(id, SEL))objc_msgSend)(dummy, sel_registerName("init"));
        if ([dummy respondsToSelector:sel]) {
            ((id(*)(id, SEL))objc_msgSend)(dummy, sel);
            m = class_getInstanceMethod(cls, sel);
        }
    }
    if (!m) return;
    IMP newImp = imp_implementationWithBlock(block);
    method_setImplementation(m, newImp);
}

%ctor {
    %init;
    dispatch_async(dispatch_get_main_queue(), ^{
        Class cls = NSClassFromString(@"YTIClientInfo");
        if (!cls) {
            YouModLogWarn(@"Spoof: YTIClientInfo not found");
            return;
        }

        SpoofSwizzleMethod(cls, @selector(clientVersion), ^NSString*(id _self) {
            if (IS_ENABLED(SpoofClientVersion)) {
                return @"21.20.4";
            }
            return ((NSString*(*)(id, SEL))objc_msgSend)(_self, @selector(clientVersion));
        });

        SpoofSwizzleMethod(cls, @selector(clientName), ^NSString*(id _self) {
            if (IS_ENABLED(SpoofWebSafari)) {
                return @"WEB_SAFARI";
            }
            return ((NSString*(*)(id, SEL))objc_msgSend)(_self, @selector(clientName));
        });

        YouModLogInfo(@"Spoof: YTIClientInfo hooks applied");
    });
}
