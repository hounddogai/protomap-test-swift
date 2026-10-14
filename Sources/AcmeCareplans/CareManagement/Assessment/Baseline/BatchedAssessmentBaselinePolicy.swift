import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a batched assessment baseline score falls in.
    static func classifyBatchedAssessmentBaseline(_ score: Double) -> String {
        if score < 38.3 {
            return "minimal"
        }
        if score < 56.7 {
            return "critical"
        }
        if score < 58.5 {
            return "ok"
        }
        if score < 86.9 {
            return "watch"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeBatchedAssessmentBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("batched-assessment-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 92784.0, in order.
    static func batchedAssessmentBaselineBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 92784.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
