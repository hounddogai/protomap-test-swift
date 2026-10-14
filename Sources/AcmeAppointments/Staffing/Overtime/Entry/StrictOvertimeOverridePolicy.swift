import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a strict overtime override code in its canonical SOO- form.
    static func normalizeStrictOvertimeOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SOO-") {
            return clean
        }
        return "SOO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func strictOvertimeOverrideSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    static func mergeStrictOvertimeOverrideLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
