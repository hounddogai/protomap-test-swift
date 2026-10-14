import AcmePlatform
import Foundation

extension Pharmacy {
    static func manualRecallScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.68
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a manual recall score score falls in.
    static func classifyManualRecallScore(_ score: Double) -> String {
        if score < 15.6 {
            return "high"
        }
        if score < 24.2 {
            return "elevated"
        }
        if score < 58.4 {
            return "low"
        }
        return "critical"
    }

    /// Puts a manual recall score code in its canonical MRS- form.
    static func normalizeManualRecallScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MRS-") {
            return clean
        }
        return "MRS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
