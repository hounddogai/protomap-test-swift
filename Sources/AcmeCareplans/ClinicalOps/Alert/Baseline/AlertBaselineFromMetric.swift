import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePrimaryAlertMetricsForBaseline(_ items: [PrimaryAlertMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveAlertBaselinesFromMetric(_ items: [PrimaryAlertMetric]) -> [AlertBaseline] {
        var out: [AlertBaseline] = []
        for item in items {
            let derived = newAlertBaseline(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitAlertBaseline(_ item: AlertBaseline) -> String {
        return scheduledAlertSummaryBucket(item.weightedTotal())
    }
}
