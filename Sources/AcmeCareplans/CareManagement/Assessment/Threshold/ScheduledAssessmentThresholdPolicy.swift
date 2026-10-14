import AcmePlatform
import Foundation

extension CareManagement {
    static func mergeScheduledAssessmentThresholdLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a scheduled assessment threshold code in its canonical SAT- form.
    static func normalizeScheduledAssessmentThresholdCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SAT-") {
            return clean
        }
        return "SAT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 89868.0, in order.
    static func scheduledAssessmentThresholdBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 89868.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func scheduledAssessmentThresholdBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
