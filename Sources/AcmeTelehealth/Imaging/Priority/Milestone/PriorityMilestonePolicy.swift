import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probePriorityMilestone() -> Int {
        let policy = Kit.Retry.defaultPolicy("priority-milestone")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a priority milestone code in its canonical PM- form.
    static func normalizePriorityMilestoneCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PM-") {
            return clean
        }
        return "PM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergePriorityMilestoneLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 3185.0, in order.
    static func priorityMilestoneBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 3185.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
