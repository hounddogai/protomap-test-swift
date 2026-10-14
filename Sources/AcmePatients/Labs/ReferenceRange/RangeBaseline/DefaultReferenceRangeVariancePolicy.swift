import AcmePlatform
import Foundation

extension Labs {
    static func defaultReferenceRangeVarianceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func defaultReferenceRangeVarianceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Puts a default reference range variance code in its canonical DRRV- form.
    static func normalizeDefaultReferenceRangeVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DRRV-") {
            return clean
        }
        return "DRRV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeDefaultReferenceRangeVarianceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
