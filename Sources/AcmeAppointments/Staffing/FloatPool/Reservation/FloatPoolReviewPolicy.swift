import AcmePlatform
import Foundation

extension Staffing {
    static func floatPoolReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a float pool review code in its canonical FPR- form.
    static func normalizeFloatPoolReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FPR-") {
            return clean
        }
        return "FPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a float pool review score falls in.
    static func classifyFloatPoolReview(_ score: Double) -> String {
        if score < 44.6 {
            return "minimal"
        }
        if score < 55.8 {
            return "watch"
        }
        if score < 56.0 {
            return "ok"
        }
        if score < 84.1 {
            return "elevated"
        }
        return "high"
    }
}
