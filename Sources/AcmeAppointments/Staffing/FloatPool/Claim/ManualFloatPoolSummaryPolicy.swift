import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualFloatPoolSummary() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-float-pool-summary")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func manualFloatPoolSummaryBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a manual float pool summary score falls in.
    static func classifyManualFloatPoolSummary(_ score: Double) -> String {
        if score < 23.2 {
            return "critical"
        }
        if score < 32.0 {
            return "low"
        }
        return "elevated"
    }
}
