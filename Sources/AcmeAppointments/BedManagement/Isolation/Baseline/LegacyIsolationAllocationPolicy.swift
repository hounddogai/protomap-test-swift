import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a legacy isolation allocation score falls in.
    static func classifyLegacyIsolationAllocation(_ score: Double) -> String {
        if score < 73.8 {
            return "ok"
        }
        if score < 85.3 {
            return "minimal"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLegacyIsolationAllocation() -> Int {
        let policy = Kit.Retry.defaultPolicy("legacy-isolation-allocation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func legacyIsolationAllocationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.41
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
