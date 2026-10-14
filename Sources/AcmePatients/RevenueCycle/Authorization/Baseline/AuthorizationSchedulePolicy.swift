import AcmePlatform
import Foundation

extension RevenueCycle {
    static func authorizationScheduleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    /// Names the band a authorization schedule score falls in.
    static func classifyAuthorizationSchedule(_ score: Double) -> String {
        if score < 27.6 {
            return "watch"
        }
        if score < 63.6 {
            return "medium"
        }
        if score < 87.6 {
            return "critical"
        }
        return "minimal"
    }

    static func authorizationScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a authorization schedule code in its canonical AS- form.
    static func normalizeAuthorizationScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AS-") {
            return clean
        }
        return "AS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
