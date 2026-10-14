import AcmePlatform
import Foundation

extension Labs {
    static func summarizeRegionalResultDigestsForAdjustment(_ items: [RegionalResultDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveLegacyAccessionAdjustmentsFromDigest(_ items: [RegionalResultDigest]) -> [LegacyAccessionAdjustment] {
        var out: [LegacyAccessionAdjustment] = []
        for item in items {
            let derived = newLegacyAccessionAdjustment(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeLegacyAccessionAdjustment(_ item: LegacyAccessionAdjustment) -> String {
        return pendingResultForecastBucket(item.adjustedExposure())
    }
}
