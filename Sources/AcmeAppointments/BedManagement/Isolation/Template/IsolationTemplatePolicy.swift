import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeIsolationTemplateLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a isolation template code in its canonical IT- form.
    static func normalizeIsolationTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IT-") {
            return clean
        }
        return "IT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
