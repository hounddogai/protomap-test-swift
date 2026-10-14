import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a scheduled risk score record score falls in.
    static func classifyScheduledRiskScoreRecord(_ score: Double) -> String {
        if score < 79.9 {
            return "medium"
        }
        if score < 81.5 {
            return "high"
        }
        return "low"
    }

    static func scheduledRiskScoreRecordBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func scheduledRiskScoreRecordWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.04
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a scheduled risk score record code in its canonical SRSR- form.
    static func normalizeScheduledRiskScoreRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRSR-") {
            return clean
        }
        return "SRSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
