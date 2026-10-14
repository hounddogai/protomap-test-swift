import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a cleaning estimate score falls in.
    static func classifyCleaningEstimate(_ score: Double) -> String {
        if score < 17.6 {
            return "critical"
        }
        if score < 37.8 {
            return "watch"
        }
        if score < 44.8 {
            return "medium"
        }
        return "ok"
    }

    /// Puts a cleaning estimate code in its canonical CE- form.
    static func normalizeCleaningEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CE-") {
            return clean
        }
        return "CE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
