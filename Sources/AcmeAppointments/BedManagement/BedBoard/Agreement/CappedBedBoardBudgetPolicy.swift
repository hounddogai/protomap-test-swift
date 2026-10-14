import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a capped bed board budget code in its canonical CBBB- form.
    static func normalizeCappedBedBoardBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CBBB-") {
            return clean
        }
        return "CBBB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func cappedBedBoardBudgetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func mergeCappedBedBoardBudgetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
