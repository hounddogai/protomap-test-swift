import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a remittance group score falls in.
    static func classifyRemittanceGroup(_ score: Double) -> String {
        if score < 11.1 {
            return "ok"
        }
        if score < 38.6 {
            return "high"
        }
        if score < 54.7 {
            return "medium"
        }
        return "minimal"
    }

    static func remittanceGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRemittanceGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("remittance-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func remittanceGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.3
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
