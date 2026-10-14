import AcmePlatform
import Foundation

extension CareManagement {
    static func mergeRollingAssessmentMappingLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 39812.0, in order.
    static func rollingAssessmentMappingBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 39812.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Names the band a rolling assessment mapping score falls in.
    static func classifyRollingAssessmentMapping(_ score: Double) -> String {
        if score < 28.9 {
            return "watch"
        }
        if score < 64.2 {
            return "minimal"
        }
        if score < 98.4 {
            return "medium"
        }
        return "high"
    }
}
