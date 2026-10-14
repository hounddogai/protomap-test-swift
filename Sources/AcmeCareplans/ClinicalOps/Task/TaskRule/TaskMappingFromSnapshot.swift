import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeLenientRoundingSnapshotsForMapping(_ items: [LenientRoundingSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveTaskMappingsFromSnapshot(_ items: [LenientRoundingSnapshot]) -> [TaskMapping] {
        var out: [TaskMapping] = []
        for item in items {
            let derived = newTaskMapping(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyTaskMapping(_ item: TaskMapping) -> Double {
        return rollingRoundingDigestWeight(7, active: true)
    }
}
