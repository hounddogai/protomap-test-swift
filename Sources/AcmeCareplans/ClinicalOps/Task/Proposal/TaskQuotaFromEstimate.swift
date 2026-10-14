import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeOrderSetEstimatesForQuota(_ items: [OrderSetEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveTaskQuotasFromEstimate(_ items: [OrderSetEstimate]) -> [TaskQuota] {
        var out: [TaskQuota] = []
        for item in items {
            let derived = newTaskQuota(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceTaskQuota(_ item: TaskQuota) -> String {
        return normalizeOrderSetAuditCode(item.code)
    }
}
