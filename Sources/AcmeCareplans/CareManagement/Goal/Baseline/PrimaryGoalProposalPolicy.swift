import AcmePlatform
import Foundation

extension CareManagement {
    static func mergePrimaryGoalProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a primary goal proposal code in its canonical PGP- form.
    static func normalizePrimaryGoalProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PGP-") {
            return clean
        }
        return "PGP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
