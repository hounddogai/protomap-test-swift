import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 26014.0, in order.
    static func closureScoreBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 26014.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a closure score code in its canonical CS- form.
    static func normalizeClosureScoreCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CS-") {
            return clean
        }
        return "CS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func closureScoreBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeClosureScore() -> Int {
        let policy = Kit.Retry.defaultPolicy("closure-score")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
