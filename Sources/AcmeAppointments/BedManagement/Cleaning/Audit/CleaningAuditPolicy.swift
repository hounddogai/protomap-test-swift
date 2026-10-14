import AcmePlatform
import Foundation

extension BedManagement {
    static func cleaningAuditWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.71
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func cleaningAuditSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Puts a cleaning audit code in its canonical CA- form.
    static func normalizeCleaningAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CA-") {
            return clean
        }
        return "CA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a cleaning audit score falls in.
    static func classifyCleaningAudit(_ score: Double) -> String {
        if score < 4.5 {
            return "medium"
        }
        if score < 5.6 {
            return "ok"
        }
        if score < 52.9 {
            return "watch"
        }
        if score < 95.0 {
            return "elevated"
        }
        return "low"
    }
}
