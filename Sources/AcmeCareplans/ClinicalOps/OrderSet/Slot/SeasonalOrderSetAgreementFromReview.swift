import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePendingAlertReviewsForAgreement(_ items: [PendingAlertReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveSeasonalOrderSetAgreementsFromReview(_ items: [PendingAlertReview]) -> [SeasonalOrderSetAgreement] {
        var out: [SeasonalOrderSetAgreement] = []
        for item in items {
            let derived = newSeasonalOrderSetAgreement(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifySeasonalOrderSetAgreementExtra(_ item: SeasonalOrderSetAgreement) -> String {
        return normalizePendingAlertReviewCode(item.code)
    }
}
