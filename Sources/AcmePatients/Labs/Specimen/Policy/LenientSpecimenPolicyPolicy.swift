import AcmePlatform
import Foundation

extension Labs {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientSpecimenPolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-specimen-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a lenient specimen policy score falls in.
    static func classifyLenientSpecimenPolicy(_ score: Double) -> String {
        if score < 24.4 {
            return "medium"
        }
        if score < 34.3 {
            return "elevated"
        }
        if score < 81.2 {
            return "critical"
        }
        return "ok"
    }
}
