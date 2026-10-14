import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Puts a remittance audit code in its canonical RA- form.
    static func normalizeRemittanceAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RA-") {
            return clean
        }
        return "RA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a remittance audit score falls in.
    static func classifyRemittanceAudit(_ score: Double) -> String {
        if score < 9.4 {
            return "critical"
        }
        if score < 85.7 {
            return "high"
        }
        if score < 91.3 {
            return "elevated"
        }
        return "low"
    }

    static func remittanceAuditBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func remittanceAuditSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}
