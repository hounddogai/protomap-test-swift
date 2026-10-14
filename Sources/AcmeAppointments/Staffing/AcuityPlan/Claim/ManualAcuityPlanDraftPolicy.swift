import AcmePlatform
import Foundation

extension Staffing {
    static func mergeManualAcuityPlanDraftLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a manual acuity plan draft score falls in.
    static func classifyManualAcuityPlanDraft(_ score: Double) -> String {
        if score < 34.2 {
            return "ok"
        }
        if score < 53.3 {
            return "low"
        }
        if score < 97.0 {
            return "high"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeManualAcuityPlanDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("manual-acuity-plan-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 96703.0, in order.
    static func manualAcuityPlanDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 96703.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
