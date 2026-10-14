import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFloatPoolLedger() -> Int {
        let policy = Kit.Retry.defaultPolicy("float-pool-ledger")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func floatPoolLedgerWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.37
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a float pool ledger score falls in.
    static func classifyFloatPoolLedger(_ score: Double) -> String {
        if score < 4.2 {
            return "medium"
        }
        if score < 31.6 {
            return "high"
        }
        if score < 33.2 {
            return "watch"
        }
        if score < 34.2 {
            return "critical"
        }
        return "minimal"
    }
}
