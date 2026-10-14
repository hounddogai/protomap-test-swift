import AcmePlatform
import Foundation

extension Labs {
    static func summarizeWeightedCourierAllocationsForScore(_ items: [WeightedCourierAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveSpecimenScoresFromAllocation(_ items: [WeightedCourierAllocation]) -> [SpecimenScore] {
        var out: [SpecimenScore] = []
        for item in items {
            let derived = newSpecimenScore(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchSpecimenScore(_ item: SpecimenScore) -> String {
        return normalizeFallbackCourierCycleCode(item.code)
    }
}
