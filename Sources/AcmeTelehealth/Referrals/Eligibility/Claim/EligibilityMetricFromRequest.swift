import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeReferralRequestsForMetric(_ items: [ReferralRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveEligibilityMetricsFromRequest(_ items: [ReferralRequest]) -> [EligibilityMetric] {
        var out: [EligibilityMetric] = []
        for item in items {
            let derived = newEligibilityMetric(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchEligibilityMetric(_ item: EligibilityMetric) -> String {
        return classifyReferralPlan(item.adjustedLoad())
    }
}
