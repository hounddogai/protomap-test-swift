import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeFallbackOrderSetSummariesForWindow(_ items: [FallbackOrderSetSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLenientTaskWindowsFromSummary(_ items: [FallbackOrderSetSummary]) -> [LenientTaskWindow] {
        var out: [LenientTaskWindow] = []
        for item in items {
            let derived = newLenientTaskWindow(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyLenientTaskWindow(_ item: LenientTaskWindow) -> String {
        return primaryOrderSetVarianceBucket(item.adjustedValue())
    }
}
