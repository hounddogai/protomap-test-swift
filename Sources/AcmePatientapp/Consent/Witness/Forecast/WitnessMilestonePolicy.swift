import AcmePlatform
import Foundation

extension Consent {
    static func witnessMilestoneBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a witness milestone score falls in.
    static func classifyWitnessMilestone(_ score: Double) -> String {
        if score < 10.4 {
            return "elevated"
        }
        if score < 16.9 {
            return "minimal"
        }
        if score < 49.3 {
            return "low"
        }
        return "ok"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWitnessMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("witness-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
