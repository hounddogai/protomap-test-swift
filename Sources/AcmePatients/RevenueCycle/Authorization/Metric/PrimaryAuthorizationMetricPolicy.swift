import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryAuthorizationMetric() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-authorization-metric")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func primaryAuthorizationMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Names the band a primary authorization metric score falls in.
    static func classifyPrimaryAuthorizationMetric(_ score: Double) -> String {
        if score < 37.7 {
            return "high"
        }
        if score < 80.5 {
            return "critical"
        }
        if score < 98.1 {
            return "low"
        }
        return "watch"
    }

    /// Puts a primary authorization metric code in its canonical PAM- form.
    static func normalizePrimaryAuthorizationMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PAM-") {
            return clean
        }
        return "PAM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
