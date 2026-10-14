import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCappedBedBoardDigestsForSegment(_ items: [CappedBedBoardDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveWeightedIsolationSegmentsFromDigest(_ items: [CappedBedBoardDigest]) -> [WeightedIsolationSegment] {
        var out: [WeightedIsolationSegment] = []
        for item in items {
            let derived = newWeightedIsolationSegment(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func planWeightedIsolationSegment(_ item: WeightedIsolationSegment) -> String {
        return bedBoardEstimateBucket(item.weightedExposure())
    }
}
