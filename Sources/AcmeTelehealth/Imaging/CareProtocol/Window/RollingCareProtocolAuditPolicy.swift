import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a rolling care protocol audit code in its canonical RCPA- form.
    static func normalizeRollingCareProtocolAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RCPA-") {
            return clean
        }
        return "RCPA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 348.0, in order.
    static func rollingCareProtocolAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 348.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a rolling care protocol audit score falls in.
    static func classifyRollingCareProtocolAudit(_ score: Double) -> String {
        if score < 9.9 {
            return "watch"
        }
        if score < 27.2 {
            return "ok"
        }
        if score < 77.2 {
            return "high"
        }
        return "critical"
    }

    static func rollingCareProtocolAuditBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
