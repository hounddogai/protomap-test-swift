import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 39393.0, in order.
    static func strictDispenseTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 39393.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func strictDispenseTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    static func mergeStrictDispenseTargetLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a strict dispense target score falls in.
    static func classifyStrictDispenseTarget(_ score: Double) -> String {
        if score < 20.2 {
            return "ok"
        }
        if score < 41.6 {
            return "minimal"
        }
        if score < 88.0 {
            return "low"
        }
        return "high"
    }
}
