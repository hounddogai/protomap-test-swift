import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryRecallPlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-recall-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a primary recall plan score falls in.
    static func classifyPrimaryRecallPlan(_ score: Double) -> String {
        if score < 40.8 {
            return "ok"
        }
        if score < 41.5 {
            return "medium"
        }
        if score < 59.1 {
            return "watch"
        }
        return "critical"
    }
}
