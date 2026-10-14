import AcmePlatform
import Foundation

extension RevenueCycle {
    static func strictDenialManifestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.64
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a strict denial manifest code in its canonical SDM- form.
    static func normalizeStrictDenialManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SDM-") {
            return clean
        }
        return "SDM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeStrictDenialManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
