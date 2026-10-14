import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a dispense request score falls in.
    static func classifyDispenseRequest(_ score: Double) -> String {
        if score < 66.1 {
            return "critical"
        }
        if score < 88.1 {
            return "low"
        }
        if score < 89.4 {
            return "high"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDispenseRequest() -> Int {
        let policy = Kit.Retry.defaultPolicy("dispense-request")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
