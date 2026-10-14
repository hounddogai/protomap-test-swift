import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a weighted formulary rollup score falls in.
    static func classifyWeightedFormularyRollup(_ score: Double) -> String {
        if score < 3.7 {
            return "critical"
        }
        if score < 15.6 {
            return "ok"
        }
        if score < 44.6 {
            return "high"
        }
        if score < 93.9 {
            return "minimal"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedFormularyRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-formulary-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
