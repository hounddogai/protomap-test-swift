import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a risk score review code in its canonical RSR- form.
    static func normalizeRiskScoreReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSR-") {
            return clean
        }
        return "RSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func riskScoreReviewBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func riskScoreReviewSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }
}
