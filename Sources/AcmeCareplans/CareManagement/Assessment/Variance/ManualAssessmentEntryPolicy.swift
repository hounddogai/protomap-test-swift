import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 4609.0, in order.
    static func manualAssessmentEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 4609.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func manualAssessmentEntrySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualAssessmentEntry() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-assessment-entry")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a manual assessment entry score falls in.
    static func classifyManualAssessmentEntry(_ score: Double) -> String {
        if score < 27.6 {
            return "minimal"
        }
        if score < 40.5 {
            return "elevated"
        }
        if score < 65.5 {
            return "critical"
        }
        return "watch"
    }
}
