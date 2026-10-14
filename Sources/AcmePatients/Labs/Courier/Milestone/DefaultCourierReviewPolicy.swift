import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a default courier review score falls in.
    static func classifyDefaultCourierReview(_ score: Double) -> String {
        if score < 55.1 {
            return "elevated"
        }
        if score < 79.6 {
            return "watch"
        }
        if score < 97.8 {
            return "low"
        }
        return "high"
    }

    /// Puts a default courier review code in its canonical DCR- form.
    static func normalizeDefaultCourierReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DCR-") {
            return clean
        }
        return "DCR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
