import AcmePlatform
import Foundation

extension Labs {
    /// Puts a reference range score code in its canonical RRS- form.
    static func normalizeReferenceRangeScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRS-") {
            return clean
        }
        return "RRS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeReferenceRangeScoreLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func referenceRangeScoreSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    static func referenceRangeScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
