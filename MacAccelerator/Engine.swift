import Foundation

//[{"HIDKeyboardModifierMappingSrc":0x700000066,"HIDKeyboardModifierMappingDst":0x700000004}]}'

public enum KeyboardUsages: UInt64 {

    case LeftControl = 0xE0
    case F19 = 0x6E
    case CapsLock = 0x39
    case Power = 0x66
    case A = 0x04

}

public class Engine {

    public func reapply() {
        let remappings: [KeyboardUsages: KeyboardUsages] = [
            .LeftControl: .F19,
            .CapsLock: .LeftControl,
        ]

        var remappingPairs: [[String: Any]] = []
        for (src, dst) in remappings {
            remappingPairs.append(MACCELRemappingPairMake(src.rawValue, dst.rawValue))
        }
        MACCELApplyKeyboardRemappings(remappingPairs)
    }

}
