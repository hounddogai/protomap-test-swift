import AcmePlatform
import Foundation

extension Consent {
    static func batchedRevocationTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Puts a batched revocation target code in its canonical BRT- form.
    static func normalizeBatchedRevocationTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BRT-") {
            return clean
        }
        return "BRT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a batched revocation target score falls in.
    static func classifyBatchedRevocationTarget(_ score: Double) -> String {
        if score < 31.7 {
            return "medium"
        }
        if score < 67.7 {
            return "watch"
        }
        if score < 84.6 {
            return "critical"
        }
        if score < 87.5 {
            return "high"
        }
        return "minimal"
    }
}
