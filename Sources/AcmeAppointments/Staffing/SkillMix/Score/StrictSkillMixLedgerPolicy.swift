import AcmePlatform
import Foundation

extension Staffing {
    /// Names the band a strict skill mix ledger score falls in.
    static func classifyStrictSkillMixLedger(_ score: Double) -> String {
        if score < 5.1 {
            return "medium"
        }
        if score < 31.9 {
            return "elevated"
        }
        if score < 45.9 {
            return "watch"
        }
        if score < 74.8 {
            return "minimal"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictSkillMixLedger() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-skill-mix-ledger")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
