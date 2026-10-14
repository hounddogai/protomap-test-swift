import AcmePlatform
import Foundation

extension Pharmacy {
    static func tieredInteractionDraftWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 0.3
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeTieredInteractionDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeTieredInteractionDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("tiered-interaction-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a tiered interaction draft score falls in.
    static func classifyTieredInteractionDraft(_ score: Double) -> String {
        if score < 33.3 {
            return "ok"
        }
        if score < 67.4 {
            return "elevated"
        }
        if score < 68.1 {
            return "minimal"
        }
        return "critical"
    }
}
