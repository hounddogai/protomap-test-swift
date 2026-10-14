import AcmePlatform
import Foundation

extension Imaging {
    static func mergeBatchedCareProtocolThresholdLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a batched care protocol threshold score falls in.
    static func classifyBatchedCareProtocolThreshold(_ score: Double) -> String {
        if score < 28.5 {
            return "elevated"
        }
        if score < 39.4 {
            return "low"
        }
        if score < 73.4 {
            return "watch"
        }
        if score < 73.6 {
            return "ok"
        }
        return "medium"
    }

    /// Counts how many amounts fit in a budget of 36975.0, in order.
    static func batchedCareProtocolThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 36975.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func batchedCareProtocolThresholdSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }
}
