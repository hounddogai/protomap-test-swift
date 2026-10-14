import AcmePlatform
import Foundation

extension CareManagement {
    static func legacyAssessmentProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func mergeLegacyAssessmentProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a legacy assessment proposal code in its canonical LAP- form.
    static func normalizeLegacyAssessmentProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LAP-") {
            return clean
        }
        return "LAP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
