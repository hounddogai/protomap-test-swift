import AcmePlatform
import Foundation

extension Consent {
    /// Puts a strict proxy variance code in its canonical SPV- form.
    static func normalizeStrictProxyVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SPV-") {
            return clean
        }
        return "SPV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func strictProxyVarianceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.51
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeStrictProxyVarianceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
