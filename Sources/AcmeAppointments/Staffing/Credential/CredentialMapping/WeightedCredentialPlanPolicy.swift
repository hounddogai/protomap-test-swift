import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a weighted credential plan code in its canonical WCP- form.
    static func normalizeWeightedCredentialPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WCP-") {
            return clean
        }
        return "WCP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeWeightedCredentialPlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
