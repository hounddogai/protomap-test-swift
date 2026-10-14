import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeLenientIsolationBaselinesForEstimate(_ items: [LenientIsolationBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveLenientCleaningEstimatesFromBaseline(_ items: [LenientIsolationBaseline]) -> [LenientCleaningEstimate] {
        var out: [LenientCleaningEstimate] = []
        for item in items {
            let derived = newLenientCleaningEstimate(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignLenientCleaningEstimate(_ item: LenientCleaningEstimate) -> String {
        return normalizeLenientIsolationBaselineCode(item.code)
    }
}
