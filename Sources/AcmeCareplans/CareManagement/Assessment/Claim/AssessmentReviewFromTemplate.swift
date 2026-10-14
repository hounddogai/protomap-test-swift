import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCappedOutreachTemplatesForReview(_ items: [CappedOutreachTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveAssessmentReviewsFromTemplate(_ items: [CappedOutreachTemplate]) -> [AssessmentReview] {
        var out: [AssessmentReview] = []
        for item in items {
            let derived = newAssessmentReview(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchAssessmentReview(_ item: AssessmentReview) -> Double {
        return cappedOutreachTemplateWeight(6, active: true)
    }
}
