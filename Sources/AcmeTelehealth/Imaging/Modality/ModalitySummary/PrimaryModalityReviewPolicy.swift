import AcmePlatform
import Foundation

extension Imaging {
    static func mergePrimaryModalityReviewLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a primary modality review score falls in.
    static func classifyPrimaryModalityReview(_ score: Double) -> String {
        if score < 21.2 {
            return "medium"
        }
        if score < 24.8 {
            return "minimal"
        }
        if score < 91.5 {
            return "ok"
        }
        return "elevated"
    }

    static func primaryModalityReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }
}
