import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a risk score checkpoint code in its canonical RSC- form.
    static func normalizeRiskScoreCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSC-") {
            return clean
        }
        return "RSC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func riskScoreCheckpointWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.0
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
