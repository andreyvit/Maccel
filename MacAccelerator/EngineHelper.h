@import Foundation;

NS_ASSUME_NONNULL_BEGIN

typedef NSDictionary<NSString *, id> MACCELRemappingPair;

MACCELRemappingPair *MACCELRemappingPairMake(uint64_t srcKey, uint64_t dstKey);

void MACCELApplyKeyboardRemappings(NSArray<MACCELRemappingPair *> *pairs);

NS_ASSUME_NONNULL_END
