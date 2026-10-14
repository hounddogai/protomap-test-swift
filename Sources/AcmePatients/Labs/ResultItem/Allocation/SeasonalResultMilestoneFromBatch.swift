import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAdaptiveSpecimenBatchesForMilestone(_ items: [AdaptiveSpecimenBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveSeasonalResultMilestonesFromBatch(_ items: [AdaptiveSpecimenBatch]) -> [SeasonalResultMilestone] {
        var out: [SeasonalResultMilestone] = []
        for item in items {
            let derived = newSeasonalResultMilestone(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateSeasonalResultMilestone(_ item: SeasonalResultMilestone) -> Double {
        return adaptiveSpecimenBundleWeight(6, active: true)
    }
}
