import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeFallbackCareProtocolSegmentsForBatch(_ items: [FallbackCareProtocolSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveWorklistBatchesFromSegment(_ items: [FallbackCareProtocolSegment]) -> [WorklistBatch] {
        var out: [WorklistBatch] = []
        for item in items {
            let derived = newWorklistBatch(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyWorklistBatch(_ item: WorklistBatch) -> String {
        return normalizeCareProtocolRuleCode(item.code)
    }
}
