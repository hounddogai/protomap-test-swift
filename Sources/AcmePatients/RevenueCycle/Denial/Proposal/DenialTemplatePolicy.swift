import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a denial template code in its canonical DT- form.
    static func normalizeDenialTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DT-") {
            return clean
        }
        return "DT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeDenialTemplateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
