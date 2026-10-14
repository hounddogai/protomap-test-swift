import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeGlobalAlertSummariesForPlan(_ items: [GlobalAlertSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAlertPlansFromSummary(_ items: [GlobalAlertSummary]) -> [AlertPlan] {
        var out: [AlertPlan] = []
        for item in items {
            let derived = newAlertPlan(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleAlertPlan(_ item: AlertPlan) -> String {
        return alertMetricBucket(item.netTotal())
    }
}
