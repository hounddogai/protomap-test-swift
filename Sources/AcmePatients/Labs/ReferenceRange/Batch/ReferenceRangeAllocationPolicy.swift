import AcmePlatform
import Foundation

extension Labs {
    static func mergeReferenceRangeAllocationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func referenceRangeAllocationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func referenceRangeAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Puts a reference range allocation code in its canonical RRA- form.
    static func normalizeReferenceRangeAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRA-") {
            return clean
        }
        return "RRA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
