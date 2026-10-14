import AcmePlatform
import Foundation

extension CareManagement {
    static func riskScoreManifestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.53
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a risk score manifest code in its canonical RSM- form.
    static func normalizeRiskScoreManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSM-") {
            return clean
        }
        return "RSM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeRiskScoreManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
