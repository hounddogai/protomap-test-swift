import AcmePlatform
import Foundation

extension CareManagement {
    static func defaultGoalManifestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.43
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func defaultGoalManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Puts a default goal manifest code in its canonical DGM- form.
    static func normalizeDefaultGoalManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DGM-") {
            return clean
        }
        return "DGM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
