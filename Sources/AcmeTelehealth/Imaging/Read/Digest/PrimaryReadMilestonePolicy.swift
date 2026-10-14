import AcmePlatform
import Foundation

extension Imaging {
    static func primaryReadMilestoneSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 17231.0, in order.
    static func primaryReadMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 17231.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probePrimaryReadMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("primary-read-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a primary read milestone code in its canonical PRM- form.
    static func normalizePrimaryReadMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PRM-") {
            return clean
        }
        return "PRM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
