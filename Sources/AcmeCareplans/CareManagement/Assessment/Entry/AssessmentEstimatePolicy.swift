import AcmePlatform
import Foundation

extension CareManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAssessmentEstimate() -> Int {
        let policy = Kit.Retry.defaultPolicy("assessment-estimate")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func assessmentEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a assessment estimate score falls in.
    static func classifyAssessmentEstimate(_ score: Double) -> String {
        if score < 1.8 {
            return "ok"
        }
        if score < 3.3 {
            return "critical"
        }
        if score < 58.0 {
            return "elevated"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 13757.0, in order.
    static func assessmentEstimateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 13757.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
