import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGlobalCareGapNoticesForBudget(_ items: [GlobalCareGapNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveWeightedAssessmentBudgetsFromNotice(_ items: [GlobalCareGapNotice]) -> [WeightedAssessmentBudget] {
        var out: [WeightedAssessmentBudget] = []
        for item in items {
            let derived = newWeightedAssessmentBudget(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeWeightedAssessmentBudget(_ item: WeightedAssessmentBudget) -> String {
        return globalCareGapNoticeBucket(item.projectedVolume())
    }
}
