import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeFormularyMilestoneLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a formulary milestone code in its canonical FM- form.
    static func normalizeFormularyMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FM-") {
            return clean
        }
        return "FM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
