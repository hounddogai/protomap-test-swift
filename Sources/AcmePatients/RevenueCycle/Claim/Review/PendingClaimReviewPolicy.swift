import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a pending claim review code in its canonical PCR- form.
    static func normalizePendingClaimReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCR-") {
            return clean
        }
        return "PCR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func pendingClaimReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Names the band a pending claim review score falls in.
    static func classifyPendingClaimReview(_ score: Double) -> String {
        if score < 73.9 {
            return "elevated"
        }
        if score < 91.9 {
            return "ok"
        }
        return "low"
    }

    static func pendingClaimReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.62
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
