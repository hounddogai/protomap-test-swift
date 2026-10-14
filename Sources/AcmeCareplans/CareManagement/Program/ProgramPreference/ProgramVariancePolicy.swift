import AcmePlatform
import Foundation

extension CareManagement {
    static func mergeProgramVarianceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func programVarianceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 51937.0, in order.
    static func programVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 51937.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a program variance score falls in.
    static func classifyProgramVariance(_ score: Double) -> String {
        if score < 14.9 {
            return "elevated"
        }
        if score < 37.1 {
            return "critical"
        }
        if score < 89.2 {
            return "medium"
        }
        if score < 92.0 {
            return "low"
        }
        return "watch"
    }
}
