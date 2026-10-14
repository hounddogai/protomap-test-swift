import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCareProtocolReviewsForTier(_ items: [CareProtocolReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveAlertTiersFromReview(_ items: [CareProtocolReview]) -> [AlertTier] {
        var out: [AlertTier] = []
        for item in items {
            let derived = newAlertTier(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planAlertTier(_ item: AlertTier) -> String {
        return careProtocolAgreementBucket(item.projectedLoad())
    }
}
