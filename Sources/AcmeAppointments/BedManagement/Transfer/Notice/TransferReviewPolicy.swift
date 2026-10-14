import AcmePlatform
import Foundation

extension BedManagement {
    static func transferReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.48
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func transferReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Names the band a transfer review score falls in.
    static func classifyTransferReview(_ score: Double) -> String {
        if score < 56.7 {
            return "low"
        }
        if score < 59.7 {
            return "ok"
        }
        if score < 62.0 {
            return "minimal"
        }
        if score < 72.0 {
            return "elevated"
        }
        return "medium"
    }

    static func transferReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
