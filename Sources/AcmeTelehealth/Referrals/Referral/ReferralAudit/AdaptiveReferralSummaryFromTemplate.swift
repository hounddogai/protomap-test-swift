import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureTemplatesForSummary(_ items: [ClosureTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAdaptiveReferralSummariesFromTemplate(_ items: [ClosureTemplate]) -> [AdaptiveReferralSummary] {
        var out: [AdaptiveReferralSummary] = []
        for item in items {
            let derived = newAdaptiveReferralSummary(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeAdaptiveReferralSummary(_ item: AdaptiveReferralSummary) -> String {
        return classifyRollingClosureProfile(item.effectiveVolume())
    }
}
