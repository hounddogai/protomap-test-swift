import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeSeasonalRiskScoreVariancesForMilestone(_ items: [SeasonalRiskScoreVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveRegionalCareGapMilestonesFromVariance(_ items: [SeasonalRiskScoreVariance]) -> [RegionalCareGapMilestone] {
        var out: [RegionalCareGapMilestone] = []
        for item in items {
            let derived = newRegionalCareGapMilestone(item.code + "-draft", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveRegionalCareGapMilestone(_ item: RegionalCareGapMilestone) -> Double {
        return riskScoreTierWeight(3, active: true)
    }
}
