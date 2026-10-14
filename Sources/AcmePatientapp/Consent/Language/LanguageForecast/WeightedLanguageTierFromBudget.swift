import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRollingDisclosureBudgetsForTier(_ items: [RollingDisclosureBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveWeightedLanguageTiersFromBudget(_ items: [RollingDisclosureBudget]) -> [WeightedLanguageTier] {
        var out: [WeightedLanguageTier] = []
        for item in items {
            let derived = newWeightedLanguageTier(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignWeightedLanguageTier(_ item: WeightedLanguageTier) -> String {
        return normalizeSeasonalDisclosureCycleCode(item.code)
    }
}
