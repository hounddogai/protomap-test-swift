import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDenialPreference() -> Int {
        let policy = Kit.Retry.defaultPolicy("denial-preference")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func denialPreferenceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a denial preference score falls in.
    static func classifyDenialPreference(_ score: Double) -> String {
        if score < 3.3 {
            return "ok"
        }
        if score < 55.2 {
            return "critical"
        }
        if score < 83.3 {
            return "elevated"
        }
        if score < 89.4 {
            return "low"
        }
        return "minimal"
    }
}
