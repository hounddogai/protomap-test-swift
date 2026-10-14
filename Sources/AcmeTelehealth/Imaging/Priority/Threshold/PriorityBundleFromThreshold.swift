import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeBatchedCareProtocolThresholdsForBundle(_ items: [BatchedCareProtocolThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func derivePriorityBundlesFromThreshold(_ items: [BatchedCareProtocolThreshold]) -> [PriorityBundle] {
        var out: [PriorityBundle] = []
        for item in items {
            let derived = newPriorityBundle(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocatePriorityBundle(_ item: PriorityBundle) -> String {
        return classifyBatchedCareProtocolThreshold(item.projectedVolume())
    }
}
