import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeSeasonalRiskScoreVariancesForRule(_ items: [SeasonalRiskScoreVariance]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveFallbackOutreachRulesFromVariance(_ items: [SeasonalRiskScoreVariance]) -> [FallbackOutreachRule] {
        var out: [FallbackOutreachRule] = []
        for item in items {
            let derived = newFallbackOutreachRule(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeFallbackOutreachRule(_ item: FallbackOutreachRule) -> String {
        return seasonalRiskScoreVarianceBucket(item.projectedTotal())
    }
}
