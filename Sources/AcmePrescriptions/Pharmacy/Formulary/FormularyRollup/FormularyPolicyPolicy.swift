import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a formulary policy code in its canonical FP- form.
    static func normalizeFormularyPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FP-") {
            return clean
        }
        return "FP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeFormularyPolicyLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func formularyPolicyWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.99
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
