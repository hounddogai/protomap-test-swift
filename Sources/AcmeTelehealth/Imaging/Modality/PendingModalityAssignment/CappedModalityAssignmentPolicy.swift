import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedModalityAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-modality-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 51216.0, in order.
    static func cappedModalityAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 51216.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func cappedModalityAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a capped modality assignment score falls in.
    static func classifyCappedModalityAssignment(_ score: Double) -> String {
        if score < 26.1 {
            return "low"
        }
        if score < 47.1 {
            return "elevated"
        }
        if score < 92.6 {
            return "medium"
        }
        return "ok"
    }
}
