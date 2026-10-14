import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRollingAlertNoticesForPlan(_ items: [RollingAlertNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveRoundingPlansFromNotice(_ items: [RollingAlertNotice]) -> [RoundingPlan] {
        var out: [RoundingPlan] = []
        for item in items {
            let derived = newRoundingPlan(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitRoundingPlan(_ item: RoundingPlan) -> Double {
        return alertEstimateWeight(2, active: true)
    }
}
