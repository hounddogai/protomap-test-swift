import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeOutreachBundlesForRule(_ items: [OutreachBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveRegionalCareGapRulesFromBundle(_ items: [OutreachBundle]) -> [RegionalCareGapRule] {
        var out: [RegionalCareGapRule] = []
        for item in items {
            let derived = newRegionalCareGapRule(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchRegionalCareGapRule(_ item: RegionalCareGapRule) -> Double {
        return outreachBundleWeight(9, active: true)
    }
}
