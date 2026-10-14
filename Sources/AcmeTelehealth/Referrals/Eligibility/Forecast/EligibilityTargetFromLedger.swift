import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeStrictSlotLedgersForTarget(_ items: [StrictSlotLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveEligibilityTargetsFromLedger(_ items: [StrictSlotLedger]) -> [EligibilityTarget] {
        var out: [EligibilityTarget] = []
        for item in items {
            let derived = newEligibilityTarget(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitEligibilityTarget(_ item: EligibilityTarget) -> Double {
        return slotExceptionWeight(6, active: true)
    }
}
