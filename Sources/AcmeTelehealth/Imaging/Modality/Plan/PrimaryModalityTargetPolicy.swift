import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryModalityTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-modality-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a primary modality target score falls in.
    static func classifyPrimaryModalityTarget(_ score: Double) -> String {
        if score < 4.3 {
            return "high"
        }
        if score < 41.8 {
            return "ok"
        }
        if score < 48.9 {
            return "medium"
        }
        if score < 87.2 {
            return "critical"
        }
        return "elevated"
    }

    static func primaryModalityTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
