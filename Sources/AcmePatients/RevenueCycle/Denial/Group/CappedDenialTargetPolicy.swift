import AcmePlatform
import Foundation

extension RevenueCycle {
    static func mergeCappedDenialTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedDenialTarget() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-denial-target")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 37027.0, in order.
    static func cappedDenialTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 37027.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func cappedDenialTargetWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.96
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
