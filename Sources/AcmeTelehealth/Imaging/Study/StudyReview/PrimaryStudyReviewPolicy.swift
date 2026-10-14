import AcmePlatform
import Foundation

extension Imaging {
    static func primaryStudyReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.35
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func primaryStudyReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    static func primaryStudyReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a primary study review code in its canonical PSR- form.
    static func normalizePrimaryStudyReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PSR-") {
            return clean
        }
        return "PSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
