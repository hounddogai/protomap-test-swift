import AcmePlatform
import Foundation

extension Labs {
    static func referenceRangeProfileBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func referenceRangeProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Puts a reference range profile code in its canonical RRP- form.
    static func normalizeReferenceRangeProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRP-") {
            return clean
        }
        return "RRP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
