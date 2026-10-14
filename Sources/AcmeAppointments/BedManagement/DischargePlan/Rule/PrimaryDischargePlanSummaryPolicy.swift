import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a primary discharge plan summary score falls in.
    static func classifyPrimaryDischargePlanSummary(_ score: Double) -> String {
        if score < 23.3 {
            return "critical"
        }
        if score < 28.9 {
            return "low"
        }
        if score < 42.8 {
            return "ok"
        }
        return "high"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryDischargePlanSummary() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-discharge-plan-summary")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
