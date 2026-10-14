import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a slot forecast code in its canonical SF- form.
    static func normalizeSlotForecastCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SF-") {
            return clean
        }
        return "SF-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func slotForecastSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }

    /// Names the band a slot forecast score falls in.
    static func classifySlotForecast(_ score: Double) -> String {
        if score < 1.2 {
            return "ok"
        }
        if score < 20.3 {
            return "medium"
        }
        if score < 21.0 {
            return "critical"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSlotForecast() -> Int {
        let policy = Kit.Retry.defaultPolicy("slot-forecast")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
