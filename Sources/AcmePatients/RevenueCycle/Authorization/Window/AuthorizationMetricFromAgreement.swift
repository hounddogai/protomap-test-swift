import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeSeasonalStatementAgreementsForMetric(_ items: [SeasonalStatementAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveAuthorizationMetricsFromAgreement(_ items: [SeasonalStatementAgreement]) -> [AuthorizationMetric] {
        var out: [AuthorizationMetric] = []
        for item in items {
            let derived = newAuthorizationMetric(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeAuthorizationMetric(_ item: AuthorizationMetric) -> String {
        return seasonalStatementPolicyBucket(item.netExposure())
    }
}
