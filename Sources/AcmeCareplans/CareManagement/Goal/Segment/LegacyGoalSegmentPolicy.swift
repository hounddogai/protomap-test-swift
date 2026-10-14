import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyGoalSegment() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-goal-segment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func legacyGoalSegmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.43
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
