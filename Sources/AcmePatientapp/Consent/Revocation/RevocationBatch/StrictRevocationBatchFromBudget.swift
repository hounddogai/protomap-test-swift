import AcmePlatform
import Foundation

extension Consent {
    static func summarizeRollingDisclosureBudgetsForBatch(_ items: [RollingDisclosureBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveStrictRevocationBatchesFromBudget(_ items: [RollingDisclosureBudget]) -> [StrictRevocationBatch] {
        var out: [StrictRevocationBatch] = []
        for item in items {
            let derived = newStrictRevocationBatch(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveStrictRevocationBatch(_ item: StrictRevocationBatch) -> String {
        return normalizeSeasonalDisclosureCycleCode(item.code)
    }
}
