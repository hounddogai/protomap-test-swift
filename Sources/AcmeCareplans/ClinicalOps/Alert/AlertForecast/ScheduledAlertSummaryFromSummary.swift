import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeScheduledTaskSummariesForSummary(_ items: [ScheduledTaskSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveScheduledAlertSummariesFromSummary(_ items: [ScheduledTaskSummary]) -> [ScheduledAlertSummary] {
        var out: [ScheduledAlertSummary] = []
        for item in items {
            let derived = newScheduledAlertSummary(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyScheduledAlertSummary(_ item: ScheduledAlertSummary) -> String {
        return taskClaimBucket(item.measuredValue())
    }
}
