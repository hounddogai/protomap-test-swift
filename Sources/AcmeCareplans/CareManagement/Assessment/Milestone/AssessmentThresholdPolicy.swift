import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 1715.0, in order.
    static func assessmentThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 1715.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeAssessmentThresholdLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a assessment threshold score falls in.
    static func classifyAssessmentThreshold(_ score: Double) -> String {
        if score < 45.6 {
            return "high"
        }
        if score < 83.1 {
            return "minimal"
        }
        return "watch"
    }
}
