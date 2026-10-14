import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a isolation agreement code in its canonical IA- form.
    static func normalizeIsolationAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IA-") {
            return clean
        }
        return "IA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeIsolationAgreementLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
