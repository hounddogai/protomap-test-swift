import AcmePlatform
import Foundation

extension Staffing {
    static func mergeRegionalFloatPoolSummaryLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a regional float pool summary code in its canonical RFPS- form.
    static func normalizeRegionalFloatPoolSummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RFPS-") {
            return clean
        }
        return "RFPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
