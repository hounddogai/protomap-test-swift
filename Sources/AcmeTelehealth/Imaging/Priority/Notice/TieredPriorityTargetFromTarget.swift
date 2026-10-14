import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeLenientStudyTargetsForTarget(_ items: [LenientStudyTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveTieredPriorityTargetsFromTarget(_ items: [LenientStudyTarget]) -> [TieredPriorityTarget] {
        var out: [TieredPriorityTarget] = []
        for item in items {
            let derived = newTieredPriorityTarget(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileTieredPriorityTarget(_ item: TieredPriorityTarget) -> String {
        return lenientStudyTargetBucket(item.weightedTotal())
    }
}
