import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizePrimaryChargeEstimatesForReview(_ items: [PrimaryChargeEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveTieredClaimReviewsFromEstimate(_ items: [PrimaryChargeEstimate]) -> [TieredClaimReview] {
        var out: [TieredClaimReview] = []
        for item in items {
            let derived = newTieredClaimReview(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeTieredClaimReview(_ item: TieredClaimReview) -> String {
        return classifyGlobalChargeAssignment(item.measuredValue())
    }
}
