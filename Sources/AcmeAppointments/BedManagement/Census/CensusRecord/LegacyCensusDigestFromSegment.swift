import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeWeightedIsolationSegmentsForDigest(_ items: [WeightedIsolationSegment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveLegacyCensusDigestsFromSegment(_ items: [WeightedIsolationSegment]) -> [LegacyCensusDigest] {
        var out: [LegacyCensusDigest] = []
        for item in items {
            let derived = newLegacyCensusDigest(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileLegacyCensusDigest(_ item: LegacyCensusDigest) -> String {
        return normalizeIsolationEntryCode(item.code)
    }
}
