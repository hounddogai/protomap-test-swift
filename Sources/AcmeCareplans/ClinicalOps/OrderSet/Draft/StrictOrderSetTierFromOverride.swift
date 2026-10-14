import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeHandoffOverridesForTier(_ items: [HandoffOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveStrictOrderSetTiersFromOverride(_ items: [HandoffOverride]) -> [StrictOrderSetTier] {
        var out: [StrictOrderSetTier] = []
        for item in items {
            let derived = newStrictOrderSetTier(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyStrictOrderSetTierExtra(_ item: StrictOrderSetTier) -> Double {
        return handoffThresholdWeight(3, active: true)
    }
}
