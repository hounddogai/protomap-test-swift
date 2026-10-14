import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 30422.0, in order.
    static func globalAssessmentReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 30422.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a global assessment review score falls in.
    static func classifyGlobalAssessmentReview(_ score: Double) -> String {
        if score < 13.6 {
            return "ok"
        }
        if score < 39.7 {
            return "critical"
        }
        return "elevated"
    }

    static func mergeGlobalAssessmentReviewLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
