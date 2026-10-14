import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalInteractionTemplate() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-interaction-template")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a global interaction template score falls in.
    static func classifyGlobalInteractionTemplate(_ score: Double) -> String {
        if score < 9.4 {
            return "watch"
        }
        if score < 77.4 {
            return "elevated"
        }
        return "critical"
    }
}
