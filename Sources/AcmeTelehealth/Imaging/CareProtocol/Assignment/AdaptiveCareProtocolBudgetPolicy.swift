import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a adaptive care protocol budget score falls in.
    static func classifyAdaptiveCareProtocolBudget(_ score: Double) -> String {
        if score < 18.9 {
            return "medium"
        }
        if score < 68.0 {
            return "low"
        }
        if score < 77.4 {
            return "critical"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveCareProtocolBudget() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-care-protocol-budget")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 1243.0, in order.
    static func adaptiveCareProtocolBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 1243.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeAdaptiveCareProtocolBudgetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
