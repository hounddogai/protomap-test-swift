import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a recall milestone code in its canonical RM- form.
    static func normalizeRecallMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RM-") {
            return clean
        }
        return "RM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRecallMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("recall-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeRecallMilestoneLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 65998.0, in order.
    static func recallMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 65998.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
