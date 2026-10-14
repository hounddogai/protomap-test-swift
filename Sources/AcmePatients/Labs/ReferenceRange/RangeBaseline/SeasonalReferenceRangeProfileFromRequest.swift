import AcmePlatform
import Foundation

extension Labs {
    static func summarizeWeightedResultRequestsForProfile(_ items: [WeightedResultRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveSeasonalReferenceRangeProfilesFromRequest(_ items: [WeightedResultRequest]) -> [SeasonalReferenceRangeProfile] {
        var out: [SeasonalReferenceRangeProfile] = []
        for item in items {
            let derived = newSeasonalReferenceRangeProfile(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreSeasonalReferenceRangeProfile(_ item: SeasonalReferenceRangeProfile) -> String {
        return legacyResultRequestBucket(item.adjustedVolume())
    }
}
