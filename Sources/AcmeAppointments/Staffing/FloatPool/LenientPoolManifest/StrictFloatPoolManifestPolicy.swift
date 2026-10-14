import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictFloatPoolManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-float-pool-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a strict float pool manifest score falls in.
    static func classifyStrictFloatPoolManifest(_ score: Double) -> String {
        if score < 36.6 {
            return "watch"
        }
        if score < 89.3 {
            return "critical"
        }
        if score < 96.0 {
            return "minimal"
        }
        return "high"
    }

    static func strictFloatPoolManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Counts how many amounts fit in a budget of 14293.0, in order.
    static func strictFloatPoolManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 14293.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
