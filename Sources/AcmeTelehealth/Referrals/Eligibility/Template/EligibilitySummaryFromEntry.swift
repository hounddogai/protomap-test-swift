import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSeasonalClosureEntriesForSummary(_ items: [SeasonalClosureEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedValue()
        }
        return totals
    }

    static func deriveEligibilitySummariesFromEntry(_ items: [SeasonalClosureEntry]) -> [EligibilitySummary] {
        var out: [EligibilitySummary] = []
        for item in items {
            let derived = newEligibilitySummary(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planEligibilitySummary(_ item: EligibilitySummary) -> Double {
        return seasonalClosureRuleWeight(2, active: true)
    }
}
