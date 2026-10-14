import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a isolation override code in its canonical IO- form.
    static func normalizeIsolationOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IO-") {
            return clean
        }
        return "IO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func isolationOverrideSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    static func isolationOverrideBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
