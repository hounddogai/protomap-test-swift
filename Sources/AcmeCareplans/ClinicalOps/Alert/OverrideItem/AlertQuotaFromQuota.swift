import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeHandoffQuotasForQuota(_ items: [HandoffQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAlertQuotasFromQuota(_ items: [HandoffQuota]) -> [AlertQuota] {
        var out: [AlertQuota] = []
        for item in items {
            let derived = newAlertQuota(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveAlertQuota(_ item: AlertQuota) -> String {
        return handoffExceptionBucket(item.projectedVolume())
    }
}
