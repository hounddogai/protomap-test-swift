import AcmePlatform
import Foundation

extension Pharmacy {
    static func batchedFormularyAuditSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Puts a batched formulary audit code in its canonical BFA- form.
    static func normalizeBatchedFormularyAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BFA-") {
            return clean
        }
        return "BFA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a batched formulary audit score falls in.
    static func classifyBatchedFormularyAudit(_ score: Double) -> String {
        if score < 50.0 {
            return "watch"
        }
        if score < 63.6 {
            return "high"
        }
        return "low"
    }
}
