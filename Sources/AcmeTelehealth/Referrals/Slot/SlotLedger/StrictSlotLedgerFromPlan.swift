import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeNetworkPlansForLedger(_ items: [NetworkPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveStrictSlotLedgersFromPlan(_ items: [NetworkPlan]) -> [StrictSlotLedger] {
        var out: [StrictSlotLedger] = []
        for item in items {
            let derived = newStrictSlotLedger(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankStrictSlotLedger(_ item: StrictSlotLedger) -> String {
        return classifyNetworkPlan(item.adjustedLoad())
    }
}
