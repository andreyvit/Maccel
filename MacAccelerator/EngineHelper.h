@import Foundation;

NS_ASSUME_NONNULL_BEGIN
CF_IMPLICIT_BRIDGING_ENABLED

typedef uint64_t MACCELKeyCode;

typedef NSDictionary<NSString *, id> MACCELRemappingPair;

MACCELRemappingPair *MACCELRemappingPairMake(MACCELKeyCode srcKey, MACCELKeyCode dstKey);

void MACCELApplyKeyboardRemappings(NSArray<MACCELRemappingPair *> *pairs);

void MACCELSendKey(MACCELKeyCode key);

typedef CGEventRef _Nullable (^MACCELTapListener)(CGEventTapProxy _Nonnull proxy, CGEventType type, CGEventRef _Nonnull event);

@interface EventTap: NSObject

- (instancetype)initWithListener:(MACCELTapListener)listener;

@property (nonatomic, readonly) BOOL isActive;

- (void)reenable;

@end

NSString *MACCELGetUnicodeString(CGEventRef event);

BOOL MACCELSelectInputSource(NSInteger sourceIndex);

CF_IMPLICIT_BRIDGING_DISABLED
NS_ASSUME_NONNULL_END
