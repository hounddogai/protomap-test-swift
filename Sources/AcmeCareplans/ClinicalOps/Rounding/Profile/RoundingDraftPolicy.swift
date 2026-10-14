import AcmePlatform
import Foundation

extension ClinicalOps {
    static func roundingDraftSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    static func roundingDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Puts a rounding draft code in its canonical RD- form.
    static func normalizeRoundingDraftCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RD-") {
            return clean
        }
        return "RD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
