import AcmePlatform
import Foundation

extension CareManagement {
    static func mergeDefaultProgramRollupLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a default program rollup score falls in.
    static func classifyDefaultProgramRollup(_ score: Double) -> String {
        if score < 5.1 {
            return "elevated"
        }
        if score < 5.3 {
            return "minimal"
        }
        if score < 17.9 {
            return "low"
        }
        if score < 53.4 {
            return "watch"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultProgramRollup() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-program-rollup")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 60886.0, in order.
    static func defaultProgramRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 60886.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
