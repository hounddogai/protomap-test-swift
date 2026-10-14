import AcmePlatform
import Foundation

extension BedManagement {
    static func globalCensusSlotWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.39
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeGlobalCensusSlotLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeGlobalCensusSlot() -> Int {
        let policy = Kit.Retry.defaultPolicy("global-census-slot")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a global census slot score falls in.
    static func classifyGlobalCensusSlot(_ score: Double) -> String {
        if score < 21.4 {
            return "critical"
        }
        if score < 71.8 {
            return "medium"
        }
        if score < 83.0 {
            return "elevated"
        }
        return "ok"
    }
}
