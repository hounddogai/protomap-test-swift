import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryWorklistSnapshot() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-worklist-snapshot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a primary worklist snapshot score falls in.
    static func classifyPrimaryWorklistSnapshot(_ score: Double) -> String {
        if score < 13.2 {
            return "watch"
        }
        if score < 18.5 {
            return "high"
        }
        if score < 31.3 {
            return "critical"
        }
        if score < 71.6 {
            return "minimal"
        }
        return "ok"
    }
}
