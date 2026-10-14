import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a adaptive closure forecast code in its canonical ACF- form.
    static func normalizeAdaptiveClosureForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ACF-") {
            return clean
        }
        return "ACF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeAdaptiveClosureForecastLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
