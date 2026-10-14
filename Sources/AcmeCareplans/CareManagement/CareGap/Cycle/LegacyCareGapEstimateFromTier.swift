import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGlobalRiskScoreTiersForEstimate(_ items: [GlobalRiskScoreTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveLegacyCareGapEstimatesFromTier(_ items: [GlobalRiskScoreTier]) -> [LegacyCareGapEstimate] {
        var out: [LegacyCareGapEstimate] = []
        for item in items {
            let derived = newLegacyCareGapEstimate(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateLegacyCareGapEstimate(_ item: LegacyCareGapEstimate) -> String {
        return normalizeSeasonalRiskScorePreferenceCode(item.code)
    }
}
