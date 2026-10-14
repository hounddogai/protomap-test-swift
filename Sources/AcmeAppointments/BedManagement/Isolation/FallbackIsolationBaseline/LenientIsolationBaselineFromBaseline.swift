import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeAdaptiveIsolationBaselinesForBaseline(_ items: [AdaptiveIsolationBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveLenientIsolationBaselinesFromBaseline(_ items: [AdaptiveIsolationBaseline]) -> [LenientIsolationBaseline] {
        var out: [LenientIsolationBaseline] = []
        for item in items {
            let derived = newLenientIsolationBaseline(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreLenientIsolationBaseline(_ item: LenientIsolationBaseline) -> String {
        return strictIsolationMilestoneBucket(item.netLoad())
    }
}
