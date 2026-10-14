import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeDischargePlanBatchLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func dischargePlanBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Names the band a discharge plan batch score falls in.
    static func classifyDischargePlanBatch(_ score: Double) -> String {
        if score < 14.0 {
            return "watch"
        }
        if score < 30.0 {
            return "ok"
        }
        if score < 79.8 {
            return "medium"
        }
        if score < 88.6 {
            return "low"
        }
        return "minimal"
    }

    /// Counts how many amounts fit in a budget of 65363.0, in order.
    static func dischargePlanBatchBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 65363.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
