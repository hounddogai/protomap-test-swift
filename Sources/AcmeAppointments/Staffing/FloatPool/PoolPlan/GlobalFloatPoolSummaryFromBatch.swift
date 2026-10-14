import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeFloatPoolBatchesForSummary(_ items: [FloatPoolBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveGlobalFloatPoolSummariesFromBatch(_ items: [FloatPoolBatch]) -> [GlobalFloatPoolSummary] {
        var out: [GlobalFloatPoolSummary] = []
        for item in items {
            let derived = newGlobalFloatPoolSummary(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyGlobalFloatPoolSummary(_ item: GlobalFloatPoolSummary) -> Double {
        return floatPoolBatchWeight(6, active: true)
    }
}
