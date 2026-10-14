import AcmePlatform
import Foundation

extension BedManagement {
    static func bedBoardProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Counts how many amounts fit in a budget of 73270.0, in order.
    static func bedBoardProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 73270.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func bedBoardProposalSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    static func mergeBedBoardProposalLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
