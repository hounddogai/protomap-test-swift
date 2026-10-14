import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeBatchedInventoryBaselinesForSegment(_ items: [BatchedInventoryBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLegacyInteractionSegmentsFromBaseline(_ items: [BatchedInventoryBaseline]) -> [LegacyInteractionSegment] {
        var out: [LegacyInteractionSegment] = []
        for item in items {
            let derived = newLegacyInteractionSegment(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectLegacyInteractionSegment(_ item: LegacyInteractionSegment) -> String {
        return batchedInventoryBaselineBucket(item.weightedExposure())
    }
}
