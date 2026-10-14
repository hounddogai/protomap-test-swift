import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackModalityAllocation() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-modality-allocation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a fallback modality allocation score falls in.
    static func classifyFallbackModalityAllocation(_ score: Double) -> String {
        if score < 25.6 {
            return "ok"
        }
        if score < 67.6 {
            return "elevated"
        }
        if score < 69.4 {
            return "high"
        }
        if score < 89.3 {
            return "low"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 40276.0, in order.
    static func fallbackModalityAllocationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 40276.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
