import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePrimaryTaskExceptionsForQuota(_ items: [PrimaryTaskException]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveCappedCareProtocolQuotasFromException(_ items: [PrimaryTaskException]) -> [CappedCareProtocolQuota] {
        var out: [CappedCareProtocolQuota] = []
        for item in items {
            let derived = newCappedCareProtocolQuota(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergeCappedCareProtocolQuota(_ item: CappedCareProtocolQuota) -> String {
        return seasonalTaskThresholdBucket(item.effectiveLoad())
    }
}
