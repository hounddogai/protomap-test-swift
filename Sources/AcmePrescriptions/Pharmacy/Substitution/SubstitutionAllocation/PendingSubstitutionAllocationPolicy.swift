import AcmePlatform
import Foundation

extension Pharmacy {
    static func pendingSubstitutionAllocationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.9
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a pending substitution allocation score falls in.
    static func classifyPendingSubstitutionAllocation(_ score: Double) -> String {
        if score < 47.9 {
            return "high"
        }
        if score < 66.7 {
            return "elevated"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePendingSubstitutionAllocation() -> Int {
        let policy = Kit.Retry.defaultPolicy("pending-substitution-allocation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergePendingSubstitutionAllocationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
