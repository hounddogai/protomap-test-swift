import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a default risk score window code in its canonical DRSW- form.
    static func normalizeDefaultRiskScoreWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DRSW-") {
            return clean
        }
        return "DRSW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func defaultRiskScoreWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.93
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
