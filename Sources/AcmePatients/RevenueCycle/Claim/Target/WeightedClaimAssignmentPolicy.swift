import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWeightedClaimAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("weighted-claim-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func weightedClaimAssignmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.17
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
