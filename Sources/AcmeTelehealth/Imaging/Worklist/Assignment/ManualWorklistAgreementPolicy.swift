import AcmePlatform
import Foundation

extension Imaging {
    static func mergeManualWorklistAgreementLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a manual worklist agreement code in its canonical MWA- form.
    static func normalizeManualWorklistAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MWA-") {
            return clean
        }
        return "MWA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
