import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeDischargePlanBatchesForEstimate(_ items: [DischargePlanBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveIsolationEstimatesFromBatch(_ items: [DischargePlanBatch]) -> [IsolationEstimate] {
        var out: [IsolationEstimate] = []
        for item in items {
            let derived = newIsolationEstimate(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileIsolationEstimate(_ item: IsolationEstimate) -> String {
        return classifyGlobalDischargePlanEstimate(item.weightedExposure())
    }
}
