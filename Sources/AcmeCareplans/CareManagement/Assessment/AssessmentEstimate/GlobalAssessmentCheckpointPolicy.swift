import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a global assessment checkpoint code in its canonical GAC- form.
    static func normalizeGlobalAssessmentCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GAC-") {
            return clean
        }
        return "GAC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func globalAssessmentCheckpointWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.29
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeGlobalAssessmentCheckpointLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
