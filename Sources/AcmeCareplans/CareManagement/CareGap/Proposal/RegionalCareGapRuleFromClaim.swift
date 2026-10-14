import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeWeightedProgramClaimsForRule(_ items: [WeightedProgramClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveRegionalCareGapRulesFromClaim(_ items: [WeightedProgramClaim]) -> [RegionalCareGapRule] {
        var out: [RegionalCareGapRule] = []
        for item in items {
            let derived = newRegionalCareGapRule(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeRegionalCareGapRule(_ item: RegionalCareGapRule) -> Double {
        return fallbackProgramNoticeWeight(2, active: true)
    }
}
