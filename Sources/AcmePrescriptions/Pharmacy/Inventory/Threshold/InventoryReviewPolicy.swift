import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeInventoryReviewLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a inventory review code in its canonical IR- form.
    static func normalizeInventoryReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IR-") {
            return clean
        }
        return "IR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a inventory review score falls in.
    static func classifyInventoryReview(_ score: Double) -> String {
        if score < 1.5 {
            return "watch"
        }
        if score < 59.0 {
            return "high"
        }
        if score < 64.9 {
            return "ok"
        }
        if score < 80.9 {
            return "elevated"
        }
        return "critical"
    }

    static func inventoryReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}
