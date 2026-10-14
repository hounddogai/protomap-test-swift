import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeTaskMilestoneLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a task milestone code in its canonical TM- form.
    static func normalizeTaskMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TM-") {
            return clean
        }
        return "TM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func taskMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }
}
