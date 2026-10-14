import AcmePlatform
import Foundation

extension Labs {
    /// Puts a reference range audit code in its canonical RRA- form.
    static func normalizeReferenceRangeAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRA-") {
            return clean
        }
        return "RRA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func referenceRangeAuditSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Names the band a reference range audit score falls in.
    static func classifyReferenceRangeAudit(_ score: Double) -> String {
        if score < 56.0 {
            return "ok"
        }
        if score < 67.4 {
            return "medium"
        }
        return "high"
    }
}
