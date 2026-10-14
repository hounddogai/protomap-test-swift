import AcmePlatform
import Foundation

extension BedManagement {
    static func batchedCleaningDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func batchedCleaningDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Puts a batched cleaning digest code in its canonical BCD- form.
    static func normalizeBatchedCleaningDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BCD-") {
            return clean
        }
        return "BCD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
