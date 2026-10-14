import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRollingDisclosureBudgetsForTarget(_ items: [RollingDisclosureBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveRegionalConsentFormTargetsFromBudget(_ items: [RollingDisclosureBudget]) -> [RegionalConsentFormTarget] {
        var out: [RegionalConsentFormTarget] = []
        for item in items {
            let derived = newRegionalConsentFormTarget(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankRegionalConsentFormTarget(_ item: RegionalConsentFormTarget) -> String {
        return normalizeSeasonalDisclosureCycleCode(item.code)
    }
}
