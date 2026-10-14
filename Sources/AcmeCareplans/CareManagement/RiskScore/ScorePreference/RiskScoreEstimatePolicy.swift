import AcmePlatform
import Foundation

extension CareManagement {
    static func riskScoreEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func riskScoreEstimateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Puts a risk score estimate code in its canonical RSE- form.
    static func normalizeRiskScoreEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSE-") {
            return clean
        }
        return "RSE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a risk score estimate score falls in.
    static func classifyRiskScoreEstimate(_ score: Double) -> String {
        if score < 29.1 {
            return "medium"
        }
        if score < 86.9 {
            return "ok"
        }
        return "high"
    }
}
