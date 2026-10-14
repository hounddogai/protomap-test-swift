import AcmePlatform
import Foundation

extension Labs {
    static func mergePanelPolicyLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a panel policy code in its canonical PP- form.
    static func normalizePanelPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PP-") {
            return clean
        }
        return "PP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
