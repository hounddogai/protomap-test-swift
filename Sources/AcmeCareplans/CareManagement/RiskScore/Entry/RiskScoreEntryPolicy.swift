import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a risk score entry code in its canonical RSE- form.
    static func normalizeRiskScoreEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSE-") {
            return clean
        }
        return "RSE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func riskScoreEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.38
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func riskScoreEntrySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }
}
