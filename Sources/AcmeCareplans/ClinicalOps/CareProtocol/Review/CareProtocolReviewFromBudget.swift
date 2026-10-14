import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeAlertBudgetsForReview(_ items: [AlertBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveCareProtocolReviewsFromBudget(_ items: [AlertBudget]) -> [CareProtocolReview] {
        var out: [CareProtocolReview] = []
        for item in items {
            let derived = newCareProtocolReview(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeCareProtocolReview(_ item: CareProtocolReview) -> String {
        return classifyAlertQuota(item.projectedVolume())
    }
}
