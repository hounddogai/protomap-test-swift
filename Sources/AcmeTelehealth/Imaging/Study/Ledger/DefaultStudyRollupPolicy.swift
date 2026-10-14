import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a default study rollup code in its canonical DSR- form.
    static func normalizeDefaultStudyRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DSR-") {
            return clean
        }
        return "DSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func defaultStudyRollupBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func defaultStudyRollupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }
}
