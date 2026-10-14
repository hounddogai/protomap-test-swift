import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeTieredHandoffOverridesForQuota(_ items: [TieredHandoffOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveBatchedCareProtocolQuotasFromOverride(_ items: [TieredHandoffOverride]) -> [BatchedCareProtocolQuota] {
        var out: [BatchedCareProtocolQuota] = []
        for item in items {
            let derived = newBatchedCareProtocolQuota(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitBatchedCareProtocolQuota(_ item: BatchedCareProtocolQuota) -> String {
        return classifyTieredHandoffOverride(item.adjustedTotal())
    }
}
