import AcmePlatform
import Foundation

extension Imaging {
    static func summarizePrimaryStudyTargetsForBundle(_ items: [PrimaryStudyTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveWeightedStudyBundlesFromTarget(_ items: [PrimaryStudyTarget]) -> [WeightedStudyBundle] {
        var out: [WeightedStudyBundle] = []
        for item in items {
            let derived = newWeightedStudyBundle(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileWeightedStudyBundle(_ item: WeightedStudyBundle) -> Double {
        return primaryStudyTargetWeight(2, active: true)
    }
}
