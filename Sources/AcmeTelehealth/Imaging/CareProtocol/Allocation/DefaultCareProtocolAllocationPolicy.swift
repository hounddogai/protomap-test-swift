import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultCareProtocolAllocation() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-care-protocol-allocation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a default care protocol allocation score falls in.
    static func classifyDefaultCareProtocolAllocation(_ score: Double) -> String {
        if score < 38.0 {
            return "ok"
        }
        if score < 45.0 {
            return "watch"
        }
        if score < 69.3 {
            return "critical"
        }
        if score < 75.8 {
            return "medium"
        }
        return "high"
    }
}
