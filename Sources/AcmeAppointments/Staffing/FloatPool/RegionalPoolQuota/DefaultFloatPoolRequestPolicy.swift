import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a default float pool request code in its canonical DFPR- form.
    static func normalizeDefaultFloatPoolRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DFPR-") {
            return clean
        }
        return "DFPR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeDefaultFloatPoolRequestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
