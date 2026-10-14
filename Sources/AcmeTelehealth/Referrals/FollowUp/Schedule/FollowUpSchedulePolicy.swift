import AcmePlatform
import Foundation

extension Referrals {
    static func followUpScheduleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.13
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func followUpScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a follow up schedule code in its canonical FUS- form.
    static func normalizeFollowUpScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FUS-") {
            return clean
        }
        return "FUS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a follow up schedule score falls in.
    static func classifyFollowUpSchedule(_ score: Double) -> String {
        if score < 50.7 {
            return "ok"
        }
        if score < 60.5 {
            return "critical"
        }
        return "minimal"
    }
}
