import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 75784.0, in order.
    static func scheduledWorklistAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 75784.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeScheduledWorklistAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("scheduled-worklist-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func scheduledWorklistAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Puts a scheduled worklist assignment code in its canonical SWA- form.
    static func normalizeScheduledWorklistAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SWA-") {
            return clean
        }
        return "SWA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
