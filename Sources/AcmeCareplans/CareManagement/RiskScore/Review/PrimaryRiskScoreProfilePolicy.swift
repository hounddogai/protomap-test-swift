import AcmePlatform
import Foundation

extension CareManagement {
    static func primaryRiskScoreProfileWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.27
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a primary risk score profile code in its canonical PRSP- form.
    static func normalizePrimaryRiskScoreProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PRSP-") {
            return clean
        }
        return "PRSP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
