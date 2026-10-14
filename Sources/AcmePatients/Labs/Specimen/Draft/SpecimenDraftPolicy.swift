import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a specimen draft score falls in.
    static func classifySpecimenDraft(_ score: Double) -> String {
        if score < 9.7 {
            return "elevated"
        }
        if score < 17.2 {
            return "watch"
        }
        if score < 34.8 {
            return "medium"
        }
        if score < 87.3 {
            return "ok"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 44774.0, in order.
    static func specimenDraftBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 44774.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSpecimenDraft() -> Int {
        let policy = Kit.Retry.defaultPolicy("specimen-draft")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
