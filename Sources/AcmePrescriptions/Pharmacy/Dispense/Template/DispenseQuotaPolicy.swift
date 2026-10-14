import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDispenseQuota() -> Int {
        let policy = Kit.Retry.defaultPolicy("dispense-quota")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a dispense quota score falls in.
    static func classifyDispenseQuota(_ score: Double) -> String {
        if score < 29.9 {
            return "watch"
        }
        if score < 69.0 {
            return "high"
        }
        if score < 99.8 {
            return "minimal"
        }
        return "low"
    }
}
