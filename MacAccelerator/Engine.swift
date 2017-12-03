import Cocoa
import Carbon

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
    case digit2
    case digit3
    case digit4
    case digit5
    case digit6
    case digit7
    case digit8
    case digit9
    case digit0
    
    case lbracket
    case rbracket
    case semicolon
    case apostrophe
    case backslash
    case comma
    case period
    case slash
    case minus
    case equals

    case enter
    case escape
    case tab
    case space
    case backspace
    case capslock
    case fn

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

    private let eventSource: CGEventSource

    fileprivate var events: [CGEvent] = []

    fileprivate init(eventSource: CGEventSource) {
        self.eventSource = eventSource
    }

    func send(_ comb: KeyComb) {
        if let events = comb.cgEvents(using: eventSource) {
            self.events.append(contentsOf: events)
        } else {
            NSLog("Cannot simulate keypress of %@", comb.description)
        }
    }

}

public protocol Action: class {
    func execute(in context: ExecutionContext)
}

public struct AppRef {
	
    public var identifier: String?
    public var name: String?
    
}

public enum BehaviorIfActive {
    case none
    case hide
}

public final class ActivateAppAction: Action {

    private let bundleIDs: [String]
    private let folderNames: [String]
    private let behaviorIfActive: BehaviorIfActive
    private var resolvedBundleIDs: [String]?

    public init(bundleIDs: [String] = [], folderNames: [String] = [], ifActive behaviorIfActive: BehaviorIfActive = .none) {
        precondition(!bundleIDs.isEmpty || !folderNames.isEmpty)
        self.bundleIDs = bundleIDs
        self.folderNames = folderNames
        self.behaviorIfActive = behaviorIfActive
    }

    public func execute(in context: ExecutionContext) {
        let resolvedBundleIDs: [String]
        if let ids = self.resolvedBundleIDs {
            resolvedBundleIDs = ids
        } else {
            resolvedBundleIDs = self.resolveBundleIDs()
            self.resolvedBundleIDs = resolvedBundleIDs
        }
        
        if behaviorIfActive == .hide {
            if let frontApp = NSWorkspace.shared().frontmostApplication, let frontID = frontApp.bundleIdentifier {
                if resolvedBundleIDs.contains(frontID) {
                    frontApp.hide()
                    return
                }
            }
        }
        for bundleID in resolvedBundleIDs {
            let apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            if !apps.isEmpty {
                apps.first!.activate(options: .activateIgnoringOtherApps)
                NSLog("Maccelerator: activated \(bundleID)")
                return
            }
        }
        for bundleID in resolvedBundleIDs {
            if NSWorkspace.shared().launchApplication(withBundleIdentifier: bundleID, options: NSWorkspaceLaunchOptions.default, additionalEventParamDescriptor: nil, launchIdentifier: nil) {
                NSLog("Maccelerator: launched \(bundleID)")
                return
            }
        }
        NSLog("Maccelerator: could not find any of the applications to launch")
    }
    
    private func resolveBundleIDs() -> [String] {
        var resolvedBundleIDs: [String] = self.bundleIDs
        if !folderNames.isEmpty {
            let applicationsDir = try! FileManager.default.url(for: .applicationDirectory, in: .localDomainMask, appropriateFor: nil, create: true)
            for folderName in folderNames {
                let bundleURL = applicationsDir.appendingPathComponent("\(folderName).app", isDirectory: true)
                if let bundle = Bundle(url: bundleURL) {
                    if let identifier = bundle.bundleIdentifier {
                        resolvedBundleIDs.append(identifier)
                    }
                }
            }
        }
        return resolvedBundleIDs
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
        context.send(comb)
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
        if flags.contains(.function) {
            insert(.fn)
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
        if flags.contains(.maskSecondaryFn) {
            insert(.fn)
        }
    }

    public static func from(key: Key) -> Modifiers {
        switch key {
        case .lcontrol, .rcontrol:  return .control
        case .lshift, .rshift:      return .shift
        case .loption, .roption:    return .option
        case .lcommand, .rcommand:  return .command
        case .fn:                   return .fn
        default:                    return .none
        }
    }

    public var keys: [Key] {
        var result: [Key] = []
        if contains(.fn) {
            result.append(.fn)
        }
        if contains(.command) {
            result.append(.lcommand)
        }
        if contains(.control) {
            result.append(.lcontrol)
        }
        if contains(.shift) {
            result.append(.lshift)
        }
        if contains(.option) {
            result.append(.loption)
        }
        return result
    }

    var cgEventFlags: CGEventFlags {
        var result: CGEventFlags = []
        if contains(.fn) {
            result.insert(.maskSecondaryFn)
        }
        if contains(.command) {
            result.insert(.maskCommand)
        }
        if contains(.control) {
            result.insert(.maskControl)
        }
        if contains(.shift) {
            result.insert(.maskShift)
        }
        if contains(.option) {
            result.insert(.maskAlternate)
        }
        return result
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
    public static let fn = Modifiers(rawValue: 0x10)

    public static let all: [Modifiers] = [.fn, .command, .control, .option, .shift]

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

    private static let textualNames: [Modifiers: String] = [.command: "command", .control: "ctrl", .option: "option", .shift: "shift", .fn: "fn"]
    private static let symbols: [Modifiers: String] = [.command: "⌘", .control: "⌃", .option: "⌥", .shift: "⇧", .fn: "fn-"]

    private static func buildDescriptions(into map: inout [Modifiers: String], names: [Modifiers: String], separator: String, from state: Modifiers = .none, appending suffixes: [Modifiers] = Modifiers.all, components: [String] = []) {
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
    
    .digit1: ["1"],
    .digit2: ["2"],
    .digit3: ["3"],
    .digit4: ["4"],
    .digit5: ["5"],
    .digit6: ["6"],
    .digit7: ["7"],
    .digit8: ["8"],
    .digit9: ["9"],
    .digit0: ["0"],

    .minus: ["minus"],
    .equals: ["equals"],
    .lbracket: ["lbracket"],
    .rbracket: ["rbracket"],
    .semicolon: ["semicolon"],
    .apostrophe: ["apostrophe"],
    .backslash: ["backslash"],
    .comma: ["comma"],
    .period: ["period"],
    .slash: ["slash"],

    .enter:       ["enter"],
    .escape:      ["esc", "escape"],
    .tab:         ["tab"],
    .space:       ["space"],
    .backspace:   ["backspace"],
    .capslock:    ["capslock", "caps"],
    .fn: ["fn"],

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
    63: .fn,

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
    
    12: .letterQ,
    13: .letterW,
    14: .letterE,
    15: .letterR,
    17: .letterT,
    16: .letterY,
    32: .letterU,
    34: .letterI,
    31: .letterO,
    35: .letterP,
    0: .letterA,
    1: .letterS,
    2: .letterD,
    3: .letterF,
    5: .letterG,
    4: .letterH,
    38: .letterJ,
    40: .letterK,
    37: .letterL,
    6: .letterZ,
    7: .letterX,
    8: .letterC,
    9: .letterV,
    11: .letterB,
    45: .letterN,
    46: .letterM,
    
    18: .digit1,
    19: .digit2,
    20: .digit3,
    21: .digit4,
    23: .digit5,
    22: .digit6,
    26: .digit7,
    28: .digit8,
    25: .digit9,
    29: .digit0,
    27: .minus,
    24: .equals,

    33: .lbracket,
    30: .rbracket,
    41: .semicolon,
    39: .apostrophe,
    42: .backslash,
    43: .comma,
    47: .period,
    44: .slash,
]

public let cgeventModifierToMask: [Key: CGEventFlags] = [
    .lshift: .maskShift,
    .rshift: .maskShift,
    .lcontrol: .maskControl,
    .rcontrol: .maskControl,
    .loption: .maskAlternate,
    .roption: .maskAlternate,
    .lcommand: .maskCommand,
    .rcommand: .maskCommand,
    .fn: .maskSecondaryFn,
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

    public func keyCombsForEventSimulation() -> [KeyComb] {
        var combs: [KeyComb] = []
        var activeModifiers: Modifiers = .none
        for key in modifiers.keys {
            combs.append(KeyComb(key, activeModifiers))
            activeModifiers.insert(Modifiers.from(key: key))
        }
        combs.append(self)
        return combs
    }

    func cgEvent(down: Bool, using eventSource: CGEventSource) -> CGEvent? {
        guard let keyCode = cgeventKeyCodes[key] else {
            return nil
        }
        let event = CGEvent(keyboardEventSource: eventSource, virtualKey: keyCode, keyDown: down)!
        event.flags = modifiers.cgEventFlags
        return event
    }

    func cgEvents(using eventSource: CGEventSource) -> [CGEvent]? {
        let subcombs = keyCombsForEventSimulation()
        var events: [CGEvent] = []
        for subcomb in subcombs {
            guard let event = subcomb.cgEvent(down: true, using: eventSource) else {
                return nil
            }
            events.append(event)
        }
        for subcomb in subcombs.reversed() {
            guard let event = subcomb.cgEvent(down: false, using: eventSource) else {
                return nil
            }
            events.append(event)
        }
        return events
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

    private var suppressModifiers: CGEventFlags = CGEventFlags(rawValue: 0)

    private let remappings: [Key: Key] = [
        .lcontrol: .f19,
        .capslock: .rcontrol,
    ]

    private let shortPressThreshold: UInt64 = 1000000 /* ns in ms */ * 175

    private let actions: [KeyComb: Action] = [
        KeyComb(.letterC, .option): ActivateAppAction(folderNames: ["Google Chrome"], ifActive: .none),
        KeyComb(.letterE, .option): ActivateAppAction(folderNames: ["Evernote"], ifActive: .hide),
        KeyComb(.letterW, .option): ActivateAppAction(folderNames: ["FaceTime"], ifActive: .hide),
        KeyComb(.letterG, .option): ActivateAppAction(folderNames: ["GitHub Desktop"], ifActive: .hide),
        KeyComb(.letterI, .option): ActivateAppAction(folderNames: ["iTunes"], ifActive: .hide),
        KeyComb(.letterM, .option): ActivateAppAction(folderNames: ["Messages"], ifActive: .hide),
        KeyComb(.letterA, .option): ActivateAppAction(folderNames: ["Safari"], ifActive: .none),
        KeyComb(.letterK, .option): ActivateAppAction(folderNames: ["Sketch"], ifActive: .none),
        KeyComb(.letterS, .option): ActivateAppAction(folderNames: ["Skype"], ifActive: .hide),
        KeyComb(.letterL, .option): ActivateAppAction(folderNames: ["Slack"], ifActive: .hide),
        KeyComb(.letterT, .option): ActivateAppAction(folderNames: ["Sublime Text"], ifActive: .none),
        KeyComb(.letterZ, .option): ActivateAppAction(folderNames: ["Telegram", "Telegram Desktop"], ifActive: .hide),
//        KeyComb(.letterH, .option): ActivateAppAction(folderNames: ["Things3", "Things"], ifActive: .hide),
        KeyComb(.letterH, .option): ActivateAppAction(folderNames: ["OmniFocus"], ifActive: .hide),
        KeyComb(.letterX, .option): ActivateAppAction(folderNames: ["Xcode"], ifActive: .none),
//        KeyComb(.letterX, [.option, .shift]): ActivateAppAction(folderNames: ["iOS Simulator"], ifActive: .hide),
        KeyComb(.letterT, .fn): SendCombAction(KeyComb(.letterX, .shift)),
    ]

    private let shortPressActions: [KeyComb: Action] = [
        KeyComb(.lcommand, .none): ActivateKeyboardLayoutAction(index: 0),
        KeyComb(.rcommand, .none): ActivateKeyboardLayoutAction(index: 1),
    ]

    private let keyDownUpActions: [KeyComb: (Action?, Action?)] = [
        :
//        KeyComb(.rcommand, .none): (ActivateKeyboardLayoutAction(index: 2),
//                                    ActivateKeyboardLayoutAction(index: 0)),
    ]

    private let eventSource = CGEventSource(stateID: CGEventSourceStateID.combinedSessionState)!

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

    private func isSingleModifierKeyComb(_ comb: KeyComb) -> Bool {
        return cgeventModifierToMask[comb.key] != nil && comb.modifiers == .none
    }

    private func handleEvent(_ proxy: CGEventTapProxy?, _ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout {
            NSLog("event tap disabled by timeout, re-enabling")
            tap.reenable()
            return Unmanaged.passUnretained(event)
        } else if type == .tapDisabledByUserInput {
            NSLog("event tap disabled by user input")
            return Unmanaged.passUnretained(event)
        }
        
        let keyCode = UInt16(event.getIntegerValueField(CGEventField.keyboardEventKeycode))
        var key = cgeventKeyCodesToKeys[keyCode] ?? .unknown

        let comb: KeyComb
        let state: KeyState
        let repeatCount: Int
        if type == .flagsChanged {
            var modifiers = Modifiers(flags: event.flags)
            let keyModifier = Modifiers.from(key: key)
//            let nsevnt = NSEvent(cgEvent: event)!
//            NSLog("%@", "flagsChanged: CGEventFlags = \(event.flags) (\(modifiers)), NSEventModifierFlags = \(nsevnt.modifierFlags) (\(Modifiers(flags: nsevnt.modifierFlags)))")
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

        if !suppressModifiers.isEmpty {
            event.flags.remove(suppressModifiers)
        }

        var actionToPerform: Action? = nil

        if isShortPressEvent, let action = shortPressActions[comb] {
            actionToPerform = action
        } else if let downUpAction = keyDownUpActions[comb] {
            actionToPerform = (state == .down ? downUpAction.0 : downUpAction.1)
            if isSingleModifierKeyComb(comb) {
                // Strip modifiers for consequent key passes if there is an action on key down. Don't bother
                // if the action is only on keyup.
                if state == .down && downUpAction.0 != nil {
                    suppressModifiers.insert(cgeventModifierToMask[comb.key]!)
                }
                // Stop stripping modifiers on keyup
                if state == .up {
                    suppressModifiers.remove(cgeventModifierToMask[comb.key]!)
                }
            }
        } else if let action = actions[comb] {
            if state == .up || repeatCount > 0 {
                return nil
            }
            actionToPerform = action
        }

        if let action = actionToPerform {
            NSLog("Executing %@", "\(action)")

            let context = ExecutionContext(eventSource: eventSource)
            action.execute(in: context)
            for event in context.events {
                event.tapPostEvent(proxy)
            }
//            if let firstEvent = context.events.first {
//                // TODO: handle the rest of them
//                return Unmanaged.passUnretained(firstEvent)
//            }
            return nil
        }

        return Unmanaged.passUnretained(event)
    }

}
