import Cocoa
import Carbon

//[{"HIDKeyboardModifierMappingSrc":0x700000066,"HIDKeyboardModifierMappingDst":0x700000004}]}'

public enum Key {
    case unknown

    case f1
    case f2
    case f3
    case f4
    case f5
    case f6
    case f7
    case f8
    case f9
    case f10
    case f11
    case f12
    case f13
    case f18
    case f19
    case f24

    case letterA
    case letterB
    case letterC
    case letterD
    case letterE
    case letterF
    case letterG
    case letterH
    case letterI
    case letterJ
    case letterK
    case letterL
    case letterM
    case letterN
    case letterO
    case letterP
    case letterQ
    case letterR
    case letterS
    case letterT
    case letterU
    case letterV
    case letterW
    case letterX
    case letterY
    case letterZ

    case digit1
    case digit0

    case enter
    case escape
    case tab
    case space
    case backspace
    case capslock

    case lcontrol
    case lshift
    case loption
    case lcommand

    case rcontrol
    case rshift
    case roption
    case rcommand

    case arrowRight
    case arrowLeft
    case arrowUp
    case arrowDown
}

public enum KeyState: CustomStringConvertible {
    case up
    case down

    public var description: String {
        switch self {
        case .up: return "↑"
        case .down: return "↓"
        }
    }
}

public enum KeyStringStyle {
    case textual
    case symbolic
}

public class ExecutionContext {

    fileprivate var events: [CGEvent] = []

}

public protocol Action: class {
    func execute(in context: ExecutionContext)
}

public final class ActivateAppAction: Action {

    private let bundleIDs: [String]
    private let hideIfActive: Bool

    public init(bundleIDs: [String], hideIfActive: Bool = false) {
        precondition(!bundleIDs.isEmpty)
        self.bundleIDs = bundleIDs
        self.hideIfActive = hideIfActive
    }

    public func execute(in context: ExecutionContext) {
        if hideIfActive {
            if let frontApp = NSWorkspace.shared().frontmostApplication, let frontID = frontApp.bundleIdentifier {
                if bundleIDs.contains(frontID) {
                    frontApp.hide()
                    return
                }
            }
        }
        NSWorkspace.shared().launchApplication(withBundleIdentifier: bundleIDs[0], options: NSWorkspaceLaunchOptions.default, additionalEventParamDescriptor: nil, launchIdentifier: nil)
    }

}

public final class ActivateKeyboardLayoutAction: Action {

    private let index: Int

    public init(index: Int) {
        self.index = index
    }

    public func execute(in context: ExecutionContext) {
        MACCELSelectInputSource(index)
    }
    
}

public final class SendCombAction: Action {

    private let comb: KeyComb

    public init(_ comb: KeyComb) {
        self.comb = comb
    }

    public func execute(in context: ExecutionContext) {
    }

}

public struct Modifiers: OptionSet, Hashable, CustomStringConvertible {

    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public init(flags: NSEventModifierFlags) {
        self.init(rawValue: 0)
        if flags.contains(.control) {
            insert(.control)
        }
        if flags.contains(.shift) {
            insert(.shift)
        }
        if flags.contains(.option) {
            insert(.option)
        }
        if flags.contains(.command) {
            insert(.command)
        }
    }

    public init(flags: CGEventFlags) {
        self.init(rawValue: 0)
        if flags.contains(.maskControl) {
            insert(.control)
        }
        if flags.contains(.maskShift) {
            insert(.shift)
        }
        if flags.contains(.maskAlternate) {
            insert(.option)
        }
        if flags.contains(.maskCommand) {
            insert(.command)
        }
    }

    public static func from(key: Key) -> Modifiers {
        switch key {
        case .lcontrol, .rcontrol:  return .control
        case .lshift, .rshift:      return .shift
        case .loption, .roption:    return .option
        case .lcommand, .rcommand:  return .command
        default:                    return .none
        }
    }

    public func string(_ style: KeyStringStyle) -> String {
        switch style {
        case .textual: return textualString
        case .symbolic: return symbolicString
        }
    }

    public var symbolicString: String {
        return Modifiers.symbolicStrings[self]!
    }

    public var textualString: String {
        return Modifiers.textualStrings[self]!
    }

    public var description: String {
        return symbolicString
    }

    public var hashValue: Int {
        return Int(rawValue)
    }

    public static let none = Modifiers(rawValue: 0)

    public static let control = Modifiers(rawValue: 0x01)
    public static let shift = Modifiers(rawValue: 0x02)
    public static let option = Modifiers(rawValue: 0x04)
    public static let command = Modifiers(rawValue: 0x08)

    private static let textualStrings: [Modifiers: String] = {
        var result: [Modifiers: String] = [:]
        buildDescriptions(into: &result, names: textualNames, separator: "-")
        return result
    }()
    private static let symbolicStrings: [Modifiers: String] = {
        var result: [Modifiers: String] = [:]
        buildDescriptions(into: &result, names: symbols, separator: "")
        return result
    }()

    private static let textualNames: [Modifiers: String] = [.command: "command", .control: "ctrl", .option: "option", .shift: "shift"]
    private static let symbols: [Modifiers: String] = [.command: "⌘", .control: "⌃", .option: "⌥", .shift: "⇧"]

    private static func buildDescriptions(into map: inout [Modifiers: String], names: [Modifiers: String], separator: String, from state: Modifiers = .none, appending suffixes: [Modifiers] = [.command, .control, .option, .shift], components: [String] = []) {
        if suffixes.isEmpty {
            map[state] = components.joined(separator: separator)
        } else {
            let current = suffixes.first!
            let remainingSuffixes = Array(suffixes.dropFirst())
            buildDescriptions(into: &map, names: names, separator: separator, from: state, appending: remainingSuffixes, components: components)
            buildDescriptions(into: &map, names: names, separator: separator, from: state.union(current), appending: remainingSuffixes, components: components + [names[current]!])
        }
    }

}

public let keyNames: [Key: [String]] = [
    .unknown:     ["unknown"],

    .letterA:     ["a"],
    .letterB:     ["b"],
    .letterC:     ["c"],
    .letterD:     ["d"],
    .letterE:     ["e"],
    .letterF:     ["f"],
    .letterG:     ["g"],
    .letterH:     ["h"],
    .letterI:     ["i"],
    .letterJ:     ["j"],
    .letterK:     ["k"],
    .letterL:     ["l"],
    .letterM:     ["m"],
    .letterN:     ["n"],
    .letterO:     ["o"],
    .letterP:     ["p"],
    .letterQ:     ["q"],
    .letterR:     ["r"],
    .letterS:     ["s"],
    .letterT:     ["t"],
    .letterU:     ["u"],
    .letterV:     ["v"],
    .letterW:     ["w"],
    .letterX:     ["x"],
    .letterY:     ["y"],
    .letterZ:     ["z"],

    .enter:       ["enter"],
    .escape:      ["esc", "escape"],
    .tab:         ["tab"],
    .space:       ["space"],
    .backspace:   ["backspace"],
    .capslock:    ["capslock", "caps"],

    .rcontrol:    ["rctrl"],
    .rshift:      ["rshift"],
    .roption:     ["roption", "ralt"],
    .rcommand:    ["rcommand"],
]

public let letterKeys: [String: Key] = [
    "a": .letterA,
    "b": .letterB,
    "c": .letterC,
    "d": .letterD,
    "e": .letterE,
    "f": .letterF,
    "g": .letterG,
    "h": .letterH,
    "i": .letterI,
    "j": .letterJ,
    "k": .letterK,
    "l": .letterL,
    "m": .letterM,
    "n": .letterN,
    "o": .letterO,
    "p": .letterP,
    "q": .letterQ,
    "r": .letterR,
    "s": .letterS,
    "t": .letterT,
    "u": .letterU,
    "v": .letterV,
    "w": .letterW,
    "x": .letterX,
    "y": .letterY,
    "z": .letterZ,
]

// see http://www.usb.org/developers/hidpage/Hut1_12v2.pdf page 53
public let usbCodes: [Key: UInt64] = [
    .letterA:     0x04,
    .letterB:     0x05,
    .letterN:     0x11,
    .letterZ:     0x1D,

    .digit1:      0x1E,
    .digit0:      0x27,

    .enter:       0x28,
    .escape:      0x29,
    .tab:         0x2B,
    .space:       0x2C,
    .capslock:    0x39,
    .f1:          0x3A,
    .f12:         0x45,

    .arrowRight:  0x4F,
    .arrowLeft:   0x50,
    .arrowDown:   0x51,
    .arrowUp:     0x52,

    .f13:         0x68,
    .f18:         0x6E,
    .f19:         0x6E,
    .f24:         0x73,

    .lcontrol:    0xE0,
    .lshift:      0xE1,
    .loption:        0xE2,
    .lcommand:    0xE3,
    .rcontrol:    0xE4,
    .rshift:      0xE5,
    .roption:        0xE6,
    .rcommand:    0xE7,
]

public let cgeventKeyCodesToKeys: [UInt16: Key] = [
    36: .enter,
    45: .letterN,
    48: .tab,
    49: .space,
    51: .backspace,
    53: .escape,

    54: .rcommand,
    55: .lcommand,
    56: .lshift,
    58: .loption,
    59: .lcontrol,
    60: .rshift,
    61: .roption,
    62: .rcontrol,

    96: .f5,
    97: .f6,
    98: .f7,
    99: .f3,
    100: .f8,
    101: .f9,
    103: .f11,
    109: .f10,
    111: .f12,
    118: .f4,
    120: .f2,
    122: .f1,

    123: .arrowLeft,
    124: .arrowRight,
    125: .arrowDown,
    126: .arrowUp,
]

public let cgeventKeyCodes: [Key: UInt16] = {
    var result: [Key: UInt16] = [:]
    for (code, key) in cgeventKeyCodesToKeys {
        result[key] = code
    }
    return result
}()

public struct KeyComb: CustomStringConvertible, Hashable {

    public var key: Key
    public var modifiers: Modifiers

    public init(_ key: Key, _ modifiers: Modifiers) {
        self.key = key
        self.modifiers = modifiers
    }

    public var description: String {
        let m = modifiers.symbolicString
        let k: String
        if let names = keyNames[key] {
            k = names.first!
        } else {
            k = "\(key)"  // emergency fallback, should never happen
        }
        return m + k
    }

    public var hashValue: Int {
        return key.hashValue ^ modifiers.hashValue
    }

    public static func ==(lhs: KeyComb, rhs: KeyComb) -> Bool {
        return (lhs.key == rhs.key) && (lhs.modifiers == rhs.modifiers)
    }

}

public struct KeyEvent {

    public var comb: KeyComb

    public var state: KeyState

    public var repeatCount: Int

    public var timestamp: CGEventTimestamp

    public var keyCode: UInt16

}

public class Engine {

    private var eventMonitor: Any?

    private var tap: EventTap!

    private var lastEvent: KeyEvent?

    private let remappings: [Key: Key] = [
        .lcontrol: .f19,
        .capslock: .rcontrol,
    ]

    private let shortPressThreshold: UInt64 = 1000000 /* ns in ms */ * 175

    private let actions: [KeyComb: Action] = [
        KeyComb(.letterN, .option): ActivateAppAction(bundleIDs: ["ru.keepcoder.Telegram"], hideIfActive: true),
    ]

    private let shortPressActions: [KeyComb: Action] = [
        KeyComb(.lcommand, .none): ActivateKeyboardLayoutAction(index: 0),
        KeyComb(.rcommand, .none): ActivateKeyboardLayoutAction(index: 1),
    ]

    public func reapply() {
        var remappingPairs: [[String: Any]] = []
        for (src, dst) in remappings {
            remappingPairs.append(MACCELRemappingPairMake(usbCodes[src]!, usbCodes[dst]!))
        }
        MACCELApplyKeyboardRemappings(remappingPairs)

        let options: [String: Any] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        if AXIsProcessTrustedWithOptions(options as CFDictionary) {
//            eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp], handler: { (event) in
//                let comb = KeyComb(event)
//                let state: KeyState = (event.type == .keyDown ? .down : .up)
//                NSLog("%@: %@", comb.description + state.description, event)
//            })

            tap = EventTap(listener: handleEvent)
            if !tap.isActive {
                NSLog("event tap failed")
            }
        }
    }

    public func cancel() {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        eventMonitor = nil
    }

    private func handleEvent(_ proxy: OpaquePointer, _ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        let keyCode = UInt16(event.getIntegerValueField(CGEventField.keyboardEventKeycode))
        var key = cgeventKeyCodesToKeys[keyCode] ?? .unknown

        let comb: KeyComb
        let state: KeyState
        let repeatCount: Int
        if type == .flagsChanged {
            var modifiers = Modifiers(flags: event.flags)
            let keyModifier = Modifiers.from(key: key)
            if modifiers.contains(keyModifier) {
                state = .down
                modifiers.remove(keyModifier)
            } else {
                state = .up
            }
            comb = KeyComb(key, modifiers)
            repeatCount = 0
        } else {
            repeatCount = Int(event.getIntegerValueField(CGEventField.keyboardEventAutorepeat))

            let str = MACCELGetUnicodeString(event).lowercased()
            if let letterKey = letterKeys[str] {
                // TODO: maybe lookup key in a default (‘english’) keyboard layout?
                key = letterKey
            }

            let modifiers = Modifiers(flags: event.flags)
            comb = KeyComb(key, modifiers)
            state = (type == .keyDown ? .down : .up)
        }

        let ev = KeyEvent(comb: comb, state: state, repeatCount: repeatCount, timestamp: event.timestamp, keyCode: keyCode)

        var isShortPressEvent = false
        if let last = lastEvent, last.state == .down, ev.state == .up, last.comb == ev.comb {
            if ev.timestamp > last.timestamp && (ev.timestamp - last.timestamp < shortPressThreshold) {
                isShortPressEvent = true
            }
        }
        lastEvent = ev

        NSLog("%@ (%@)", comb.description + state.description, "\(keyCode)")
        // NSLog("%@", NSEvent(cgEvent: event)!)

        if isShortPressEvent, let action = shortPressActions[comb] {
            NSLog("Executing %@", "\(action)")
            let context = ExecutionContext()
            action.execute(in: context)
            return Unmanaged.passUnretained(event)
        }

        if let action = actions[comb] {
            NSLog("Executing %@", "\(action)")

            if state == .up || repeatCount > 0 {
                return nil
            }
            let context = ExecutionContext()
            action.execute(in: context)
            if let firstEvent = context.events.first {
                // TODO: handle the rest of them
                return Unmanaged.passUnretained(firstEvent)
            } else {
                return nil
            }
        }

        return Unmanaged.passUnretained(event)
    }

}
