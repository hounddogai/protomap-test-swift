import AcmePlatform
import Foundation

extension CareManagement {
    static func manualRiskScoreAuditWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.86
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a manual risk score audit code in its canonical MRSA- form.
    static func normalizeManualRiskScoreAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MRSA-") {
            return clean
        }
        return "MRSA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a manual risk score audit score falls in.
    static func classifyManualRiskScoreAudit(_ score: Double) -> String {
        if score < 22.1 {
            return "watch"
        }
        if score < 98.7 {
            return "high"
        }
        return "medium"
    }

    static func manualRiskScoreAuditBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
