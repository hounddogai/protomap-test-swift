import AcmePlatform
import Foundation

extension CareManagement {
    static func mergeAdaptiveAssessmentThresholdLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 58774.0, in order.
    static func adaptiveAssessmentThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 58774.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func adaptiveAssessmentThresholdBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Names the band a adaptive assessment threshold score falls in.
    static func classifyAdaptiveAssessmentThreshold(_ score: Double) -> String {
        if score < 4.3 {
            return "ok"
        }
        if score < 18.8 {
            return "low"
        }
        if score < 44.8 {
            return "elevated"
        }
        return "high"
    }
}
