import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a read manifest code in its canonical RM- form.
    static func normalizeReadManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RM-") {
            return clean
        }
        return "RM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func readManifestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.54
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
