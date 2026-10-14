import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 56445.0, in order.
    static func assessmentAssignmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 56445.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func assessmentAssignmentBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a assessment assignment code in its canonical AA- form.
    static func normalizeAssessmentAssignmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AA-") {
            return clean
        }
        return "AA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func assessmentAssignmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
