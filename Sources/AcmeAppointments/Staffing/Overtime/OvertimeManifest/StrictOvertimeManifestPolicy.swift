import AcmePlatform
import Foundation

extension Staffing {
    static func strictOvertimeManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Names the band a strict overtime manifest score falls in.
    static func classifyStrictOvertimeManifest(_ score: Double) -> String {
        if score < 17.3 {
            return "medium"
        }
        if score < 72.0 {
            return "minimal"
        }
        if score < 98.3 {
            return "high"
        }
        return "critical"
    }

    /// Counts how many amounts fit in a budget of 57707.0, in order.
    static func strictOvertimeManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 57707.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictOvertimeManifest() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-overtime-manifest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
