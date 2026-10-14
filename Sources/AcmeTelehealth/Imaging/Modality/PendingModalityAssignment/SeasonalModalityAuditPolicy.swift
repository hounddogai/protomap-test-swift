import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a seasonal modality audit score falls in.
    static func classifySeasonalModalityAudit(_ score: Double) -> String {
        if score < 28.3 {
            return "critical"
        }
        if score < 97.0 {
            return "ok"
        }
        return "minimal"
    }

    /// Puts a seasonal modality audit code in its canonical SMA- form.
    static func normalizeSeasonalModalityAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SMA-") {
            return clean
        }
        return "SMA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func seasonalModalityAuditSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }
}
