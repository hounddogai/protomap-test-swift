import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeInteractionAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeInteractionAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("interaction-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func interactionAssignmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.78
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
