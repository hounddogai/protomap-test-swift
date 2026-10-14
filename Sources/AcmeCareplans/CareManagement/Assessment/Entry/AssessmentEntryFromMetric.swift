import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRiskScoreMetricsForEntry(_ items: [RiskScoreMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAssessmentEntriesFromMetric(_ items: [RiskScoreMetric]) -> [AssessmentEntry] {
        var out: [AssessmentEntry] = []
        for item in items {
            let derived = newAssessmentEntry(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceAssessmentEntry(_ item: AssessmentEntry) -> String {
        return classifyRiskScoreGroup(item.effectiveLoad())
    }
}
