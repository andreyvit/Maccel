#import "EngineHelper.h"
@import Carbon;

#import <IOKit/hidsystem/IOHIDEventSystemClient.h>
#import <IOKit/hidsystem/IOHIDServiceClient.h>
#import <IOKit/hid/IOHIDUsageTables.h>

MACCELRemappingPair *MACCELRemappingPairMake(MACCELKeyCode srcKey, MACCELKeyCode dstKey) {
    return @{
        @kIOHIDKeyboardModifierMappingSrcKey:@(0x700000000 | srcKey),
        @kIOHIDKeyboardModifierMappingDstKey:@(0x700000000 | dstKey),
    };
}

void MACCELApplyKeyboardRemappings(NSArray<MACCELRemappingPair *> *pairs) {
    NSLog(@"MACCEL: Applying remappings: %@", pairs);
    IOHIDEventSystemClientRef system = IOHIDEventSystemClientCreateSimpleClient(kCFAllocatorDefault);
    CFArrayRef services = IOHIDEventSystemClientCopyServices(system);
    for(CFIndex i = 0; i < CFArrayGetCount(services); i++) {
        IOHIDServiceClientRef service = (IOHIDServiceClientRef)CFArrayGetValueAtIndex(services, i);
        if(IOHIDServiceClientConformsTo(service, kHIDPage_GenericDesktop, kHIDUsage_GD_Keyboard)) {
            IOHIDServiceClientSetProperty(service, CFSTR(kIOHIDUserKeyUsageMapKey), (CFArrayRef)pairs);
        }
    }
    NSLog(@"MACCEL: Remappings applied.");
    CFRelease(services);
    CFRelease(system);
}



@implementation EventTap {
    MACCELTapListener _listener;
    CFMachPortRef _port;
}

static CGEventRef MACCELEventTapFunction(CGEventTapProxy proxy, CGEventType type, CGEventRef event, void *refcon) {
    if (type != kCGEventKeyDown && type != kCGEventKeyUp && type != kCGEventFlagsChanged) {
        return event;
    }

    EventTap *tap = (__bridge EventTap *)refcon;
    return [tap handleEvent:event type:type proxy:proxy];
}

- (instancetype)initWithListener:(MACCELTapListener)listener {
    self = [super init];
    if (!self) {
        return nil;
    }

    _listener = listener;

    CGEventMask keyboardMask = CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventKeyUp) | CGEventMaskBit(kCGEventFlagsChanged);

    _port = CGEventTapCreate(kCGAnnotatedSessionEventTap, kCGTailAppendEventTap, kCGEventTapOptionDefault, keyboardMask, (CGEventTapCallBack)MACCELEventTapFunction, (__bridge void *)self);
    if (!_port) {
        NSLog(@"CGEventTapCreate failed");
        return self;
    }

    CFRunLoopSourceRef source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, _port, 0);
    if (!source) {
        NSLog(@"CFMachPortCreateRunLoopSource failed");
        return self;
    }

    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    if (!runLoop) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"no run loop" userInfo:nil];
    }
    CFRunLoopAddSource(runLoop, source, kCFRunLoopDefaultMode);
    CFRelease(source);

    _isActive = YES;
    return self;
}

- (void)dealloc {
    if (_port) {
        CFRelease(_port);
        _port = nil;
    }
}

- (CGEventRef _Nullable)handleEvent:(CGEventRef)event type:(CGEventType)type proxy:(CGEventTapProxy)proxy {
    return _listener(proxy, type, event);
}

- (void)reenable {
    CGEventTapEnable(_port, true);
}

NSString *MACCELGetUnicodeString(CGEventRef event) {
    UniCharCount len = 0;
    CGEventKeyboardGetUnicodeString(event, 0, &len, NULL);

    UniChar buf[len];
    UniCharCount maxlen = len;
    CGEventKeyboardGetUnicodeString(event, maxlen, &len, buf);

    return [NSString stringWithCharacters:buf length:len];
}

BOOL MACCELSelectInputSource(NSString *sourceID) {
    NSArray *sources = (__bridge_transfer NSArray *)TISCreateInputSourceList(nil, false);
    NSInteger idx = 0;
    BOOL ok = NO;
    for (id source in sources) {
        NSString *candidateID = (__bridge NSString *) (CFStringRef)TISGetInputSourceProperty((__bridge TISInputSourceRef)source, kTISPropertyInputSourceID);
        NSString *cat = (__bridge NSString *) (CFStringRef)TISGetInputSourceProperty((__bridge TISInputSourceRef)source, kTISPropertyInputSourceCategory);
        NSString *type = (__bridge NSString *) (CFStringRef)TISGetInputSourceProperty((__bridge TISInputSourceRef)source, kTISPropertyInputSourceType);
        NSLog(@"Source %ld: %@ (category %@, type %@) - %@", (long)idx, candidateID, cat, type, source);

        if ([candidateID isEqualToString:sourceID]) {
            OSStatus status = TISSelectInputSource((__bridge TISInputSourceRef)source);
            if (status == noErr) {
                ok = true;
            } else {
                NSLog(@"TISSelectInputSource failed with status %@", @(status));
            }
        }

        idx++;
    }
    return ok;
}

@end
