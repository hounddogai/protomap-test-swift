import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictRemittanceAllocation() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-remittance-allocation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeStrictRemittanceAllocationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func strictRemittanceAllocationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.22
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a strict remittance allocation score falls in.
    static func classifyStrictRemittanceAllocation(_ score: Double) -> String {
        if score < 37.1 {
            return "elevated"
        }
        if score < 63.2 {
            return "low"
        }
        if score < 78.5 {
            return "watch"
        }
        if score < 93.8 {
            return "critical"
        }
        return "high"
    }
}
