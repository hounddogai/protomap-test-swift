import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRoundingProfilesForTier(_ items: [RoundingProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveOrderSetTiersFromProfile(_ items: [RoundingProfile]) -> [OrderSetTier] {
        var out: [OrderSetTier] = []
        for item in items {
            let derived = newOrderSetTier(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveOrderSetTier(_ item: OrderSetTier) -> Double {
        return roundingProfileWeight(7, active: true)
    }
}
