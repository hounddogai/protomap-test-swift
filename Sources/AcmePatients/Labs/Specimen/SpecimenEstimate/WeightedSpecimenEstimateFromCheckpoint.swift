import AcmePlatform
import Foundation

extension Labs {
    static func summarizeRegionalAccessionCheckpointsForEstimate(_ items: [RegionalAccessionCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveWeightedSpecimenEstimatesFromCheckpoint(_ items: [RegionalAccessionCheckpoint]) -> [WeightedSpecimenEstimate] {
        var out: [WeightedSpecimenEstimate] = []
        for item in items {
            let derived = newWeightedSpecimenEstimate(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreWeightedSpecimenEstimate(_ item: WeightedSpecimenEstimate) -> String {
        return accessionAssignmentBucket(item.adjustedValue())
    }
}
