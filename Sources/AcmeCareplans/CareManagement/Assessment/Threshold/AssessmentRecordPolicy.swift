import AcmePlatform
import Foundation

extension CareManagement {
    static func mergeAssessmentRecordLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a assessment record code in its canonical AR- form.
    static func normalizeAssessmentRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AR-") {
            return clean
        }
        return "AR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
