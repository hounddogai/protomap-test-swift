import AcmePlatform
import Foundation

extension Consent {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWitnessRequest() -> Int {
        let policy = Kit.Retry.defaultPolicy("witness-request")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func witnessRequestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a witness request score falls in.
    static func classifyWitnessRequest(_ score: Double) -> String {
        if score < 16.8 {
            return "ok"
        }
        if score < 61.3 {
            return "medium"
        }
        if score < 81.4 {
            return "low"
        }
        if score < 94.1 {
            return "minimal"
        }
        return "critical"
    }
}
