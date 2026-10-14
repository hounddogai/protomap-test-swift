import AcmePlatform
import Foundation

extension Consent {
    /// Puts a global revocation group code in its canonical GRG- form.
    static func normalizeGlobalRevocationGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GRG-") {
            return clean
        }
        return "GRG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeGlobalRevocationGroupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func globalRevocationGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.39
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
