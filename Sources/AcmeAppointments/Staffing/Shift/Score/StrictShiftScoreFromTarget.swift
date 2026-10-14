import AcmePlatform
import Foundation

extension Staffing {
    static func summarizePendingFloatPoolTargetsForScore(_ items: [PendingFloatPoolTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveStrictShiftScoresFromTarget(_ items: [PendingFloatPoolTarget]) -> [StrictShiftScore] {
        var out: [StrictShiftScore] = []
        for item in items {
            let derived = newStrictShiftScore(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeStrictShiftScore(_ item: StrictShiftScore) -> String {
        return floatPoolBundleBucket(item.effectiveLoad())
    }
}
