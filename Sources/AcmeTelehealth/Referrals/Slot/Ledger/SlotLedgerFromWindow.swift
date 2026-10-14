import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureWindowsForLedger(_ items: [ClosureWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveSlotLedgersFromWindow(_ items: [ClosureWindow]) -> [SlotLedger] {
        var out: [SlotLedger] = []
        for item in items {
            let derived = newSlotLedger(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeSlotLedger(_ item: SlotLedger) -> Double {
        return closureWindowWeight(1, active: true)
    }
}
