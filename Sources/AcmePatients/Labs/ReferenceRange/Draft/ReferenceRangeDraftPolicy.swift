import AcmePlatform
import Foundation

extension Labs {
    /// Counts how many amounts fit in a budget of 48513.0, in order.
    static func referenceRangeDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 48513.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeReferenceRangeDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeReferenceRangeDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("reference-range-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func referenceRangeDraftWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.08
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
