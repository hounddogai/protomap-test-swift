import AcmePlatform
import Foundation

extension Consent {
    static func summarizeSeasonalConsentFormSlotsForGroup(_ items: [SeasonalConsentFormSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveWeightedProxyGroupsFromSlot(_ items: [SeasonalConsentFormSlot]) -> [WeightedProxyGroup] {
        var out: [WeightedProxyGroup] = []
        for item in items {
            let derived = newWeightedProxyGroup(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveWeightedProxyGroup(_ item: WeightedProxyGroup) -> Double {
        return regionalConsentFormTargetWeight(3, active: true)
    }
}
