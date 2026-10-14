import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a scheduled statement notice score falls in.
    static func classifyScheduledStatementNotice(_ score: Double) -> String {
        if score < 4.8 {
            return "critical"
        }
        if score < 14.0 {
            return "low"
        }
        if score < 25.0 {
            return "ok"
        }
        if score < 56.9 {
            return "high"
        }
        return "medium"
    }

    /// Puts a scheduled statement notice code in its canonical SSN- form.
    static func normalizeScheduledStatementNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SSN-") {
            return clean
        }
        return "SSN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func scheduledStatementNoticeWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.42
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 27551.0, in order.
    static func scheduledStatementNoticeBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 27551.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
