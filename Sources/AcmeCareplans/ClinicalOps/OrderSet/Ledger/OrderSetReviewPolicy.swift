import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a order set review score falls in.
    static func classifyOrderSetReview(_ score: Double) -> String {
        if score < 27.0 {
            return "watch"
        }
        if score < 60.5 {
            return "elevated"
        }
        if score < 73.9 {
            return "medium"
        }
        return "ok"
    }

    static func mergeOrderSetReviewLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a order set review code in its canonical OSR- form.
    static func normalizeOrderSetReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OSR-") {
            return clean
        }
        return "OSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func orderSetReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }
}
