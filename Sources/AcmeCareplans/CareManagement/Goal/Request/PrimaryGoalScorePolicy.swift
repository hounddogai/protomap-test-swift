import AcmePlatform
import Foundation

extension CareManagement {
    static func primaryGoalScoreSpan(_ start: Int, end: Int) -> Int {
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
    static func probePrimaryGoalScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-goal-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a primary goal score code in its canonical PGS- form.
    static func normalizePrimaryGoalScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PGS-") {
            return clean
        }
        return "PGS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 74473.0, in order.
    static func primaryGoalScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 74473.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
