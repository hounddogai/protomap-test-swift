import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRiskScoreClaimsForPlan(_ items: [RiskScoreClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePrimaryOutreachPlansFromClaim(_ items: [RiskScoreClaim]) -> [PrimaryOutreachPlan] {
        var out: [PrimaryOutreachPlan] = []
        for item in items {
            let derived = newPrimaryOutreachPlan(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcilePrimaryOutreachPlan(_ item: PrimaryOutreachPlan) -> String {
        return riskScorePreferenceBucket(item.effectiveValue())
    }
}
