#import "EngineHelper.h"

#import <IOKit/hidsystem/IOHIDEventSystemClient.h>
#import <IOKit/hidsystem/IOHIDServiceClient.h>
#import <IOKit/hid/IOHIDUsageTables.h>

MACCELRemappingPair *MACCELRemappingPairMake(uint64_t srcKey, uint64_t dstKey) {
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
