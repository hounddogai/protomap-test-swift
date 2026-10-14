import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotTargetsForMapping(_ items: [SlotTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveClosureMappingsFromTarget(_ items: [SlotTarget]) -> [ClosureMapping] {
        var out: [ClosureMapping] = []
        for item in items {
            let derived = newClosureMapping(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchClosureMapping(_ item: ClosureMapping) -> Double {
        return slotTargetWeight(2, active: true)
    }
}
