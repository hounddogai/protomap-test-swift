import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRiskScoreSummariesForAdjustment(_ items: [RiskScoreSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveRollingCareGapAdjustmentsFromSummary(_ items: [RiskScoreSummary]) -> [RollingCareGapAdjustment] {
        var out: [RollingCareGapAdjustment] = []
        for item in items {
            let derived = newRollingCareGapAdjustment(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankRollingCareGapAdjustment(_ item: RollingCareGapAdjustment) -> String {
        return riskScoreSummaryBucket(item.weightedExposure())
    }
}
