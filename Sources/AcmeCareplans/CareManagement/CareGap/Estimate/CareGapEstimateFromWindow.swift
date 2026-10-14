import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeWeightedCareGapWindowsForEstimate(_ items: [WeightedCareGapWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveCareGapEstimatesFromWindow(_ items: [WeightedCareGapWindow]) -> [CareGapEstimate] {
        var out: [CareGapEstimate] = []
        for item in items {
            let derived = newCareGapEstimate(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreCareGapEstimate(_ item: CareGapEstimate) -> String {
        return globalCareGapAssignmentBucket(item.netTotal())
    }
}
