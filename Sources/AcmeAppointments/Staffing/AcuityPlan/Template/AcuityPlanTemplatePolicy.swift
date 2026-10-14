import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a acuity plan template score falls in.
    static func classifyAcuityPlanTemplate(_ score: Double) -> String {
        if score < 34.2 {
            return "watch"
        }
        if score < 40.1 {
            return "ok"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAcuityPlanTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("acuity-plan-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
