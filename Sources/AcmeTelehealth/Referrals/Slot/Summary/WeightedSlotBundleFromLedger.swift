import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeDefaultSlotLedgersForBundle(_ items: [DefaultSlotLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveWeightedSlotBundlesFromLedger(_ items: [DefaultSlotLedger]) -> [WeightedSlotBundle] {
        var out: [WeightedSlotBundle] = []
        for item in items {
            let derived = newWeightedSlotBundle(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreWeightedSlotBundle(_ item: WeightedSlotBundle) -> String {
        return normalizeSlotQuotaCode(item.code)
    }
}
