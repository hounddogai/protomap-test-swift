import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeGlobalFormularyAllocationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a global formulary allocation code in its canonical GFA- form.
    static func normalizeGlobalFormularyAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GFA-") {
            return clean
        }
        return "GFA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
