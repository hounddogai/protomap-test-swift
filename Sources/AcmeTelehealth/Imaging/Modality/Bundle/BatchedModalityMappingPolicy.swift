import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 41754.0, in order.
    static func batchedModalityMappingBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 41754.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedModalityMapping() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-modality-mapping")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a batched modality mapping score falls in.
    static func classifyBatchedModalityMapping(_ score: Double) -> String {
        if score < 1.7 {
            return "minimal"
        }
        if score < 12.9 {
            return "elevated"
        }
        if score < 63.8 {
            return "medium"
        }
        if score < 93.9 {
            return "ok"
        }
        return "watch"
    }

    static func batchedModalityMappingWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.86
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
