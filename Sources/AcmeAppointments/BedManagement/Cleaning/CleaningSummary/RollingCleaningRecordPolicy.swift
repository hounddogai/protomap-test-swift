import AcmePlatform
import Foundation

extension BedManagement {
    static func rollingCleaningRecordWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.3
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a rolling cleaning record code in its canonical RCR- form.
    static func normalizeRollingCleaningRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RCR-") {
            return clean
        }
        return "RCR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a rolling cleaning record score falls in.
    static func classifyRollingCleaningRecord(_ score: Double) -> String {
        if score < 48.5 {
            return "medium"
        }
        if score < 65.7 {
            return "high"
        }
        return "ok"
    }
}
