import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePriorityAgreement() -> Int {
        let policy = Kit.Retry.defaultPolicy("priority-agreement")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a priority agreement score falls in.
    static func classifyPriorityAgreement(_ score: Double) -> String {
        if score < 9.2 {
            return "low"
        }
        if score < 31.6 {
            return "watch"
        }
        if score < 77.1 {
            return "minimal"
        }
        return "critical"
    }

    static func priorityAgreementWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.8
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 95262.0, in order.
    static func priorityAgreementBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 95262.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
