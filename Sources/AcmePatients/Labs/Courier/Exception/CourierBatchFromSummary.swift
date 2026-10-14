import AcmePlatform
import Foundation

extension Labs {
    static func summarizeReferenceRangeSummariesForBatch(_ items: [ReferenceRangeSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveCourierBatchesFromSummary(_ items: [ReferenceRangeSummary]) -> [CourierBatch] {
        var out: [CourierBatch] = []
        for item in items {
            let derived = newCourierBatch(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectCourierBatch(_ item: CourierBatch) -> String {
        return classifyReferenceRangeForecast(item.projectedLoad())
    }
}
