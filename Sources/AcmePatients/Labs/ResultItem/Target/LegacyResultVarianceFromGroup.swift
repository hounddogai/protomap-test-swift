import AcmePlatform
import Foundation

extension Labs {
    static func summarizePrimaryAccessionGroupsForVariance(_ items: [PrimaryAccessionGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLegacyResultVariancesFromGroup(_ items: [PrimaryAccessionGroup]) -> [LegacyResultVariance] {
        var out: [LegacyResultVariance] = []
        for item in items {
            let derived = newLegacyResultVariance(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchLegacyResultVariance(_ item: LegacyResultVariance) -> String {
        return lenientAccessionCheckpointBucket(item.projectedVolume())
    }
}
