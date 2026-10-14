import AcmePlatform
import Foundation

extension RevenueCycle {
    static func mergePrimaryRemittancePlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a primary remittance plan score falls in.
    static func classifyPrimaryRemittancePlan(_ score: Double) -> String {
        if score < 10.0 {
            return "minimal"
        }
        if score < 45.3 {
            return "medium"
        }
        if score < 51.3 {
            return "low"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryRemittancePlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-remittance-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
