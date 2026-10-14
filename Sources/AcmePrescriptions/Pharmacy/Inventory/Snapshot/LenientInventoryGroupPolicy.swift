import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a lenient inventory group score falls in.
    static func classifyLenientInventoryGroup(_ score: Double) -> String {
        if score < 73.6 {
            return "medium"
        }
        if score < 76.2 {
            return "low"
        }
        if score < 92.8 {
            return "elevated"
        }
        if score < 97.1 {
            return "ok"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientInventoryGroup() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-inventory-group")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 79618.0, in order.
    static func lenientInventoryGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 79618.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
