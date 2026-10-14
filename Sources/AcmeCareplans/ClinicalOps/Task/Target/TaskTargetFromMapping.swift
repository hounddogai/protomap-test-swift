import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeLegacyRoundingMappingsForTarget(_ items: [LegacyRoundingMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveTaskTargetsFromMapping(_ items: [LegacyRoundingMapping]) -> [TaskTarget] {
        var out: [TaskTarget] = []
        for item in items {
            let derived = newTaskTarget(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }
}
