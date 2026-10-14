import AcmePlatform
import Foundation

extension CareManagement {
    static func assessmentSnapshotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    static func mergeAssessmentSnapshotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a assessment snapshot code in its canonical AS- form.
    static func normalizeAssessmentSnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AS-") {
            return clean
        }
        return "AS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
