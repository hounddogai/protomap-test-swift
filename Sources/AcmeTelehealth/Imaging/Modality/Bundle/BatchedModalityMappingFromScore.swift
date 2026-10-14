import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePriorityScoresForMapping(_ items: [PriorityScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveBatchedModalityMappingsFromScore(_ items: [PriorityScore]) -> [BatchedModalityMapping] {
        var out: [BatchedModalityMapping] = []
        for item in items {
            let derived = newBatchedModalityMapping(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeBatchedModalityMapping(_ item: BatchedModalityMapping) -> String {
        return normalizePriorityTemplateCode(item.code)
    }
}
