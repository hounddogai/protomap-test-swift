import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSeasonalClosureMetricsForCycle(_ items: [SeasonalClosureMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveGlobalReferralCyclesFromMetric(_ items: [SeasonalClosureMetric]) -> [GlobalReferralCycle] {
        var out: [GlobalReferralCycle] = []
        for item in items {
            let derived = newGlobalReferralCycle(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planGlobalReferralCycle(_ item: GlobalReferralCycle) -> String {
        return cappedClosureNoticeBucket(item.effectiveValue())
    }
}
