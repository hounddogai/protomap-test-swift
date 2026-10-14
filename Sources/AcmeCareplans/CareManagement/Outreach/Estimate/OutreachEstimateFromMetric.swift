import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAdaptiveAssessmentMetricsForEstimate(_ items: [AdaptiveAssessmentMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveOutreachEstimatesFromMetric(_ items: [AdaptiveAssessmentMetric]) -> [OutreachEstimate] {
        var out: [OutreachEstimate] = []
        for item in items {
            let derived = newOutreachEstimate(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceOutreachEstimate(_ item: OutreachEstimate) -> String {
        return classifyFallbackAssessmentMilestone(item.measuredValue())
    }
}
