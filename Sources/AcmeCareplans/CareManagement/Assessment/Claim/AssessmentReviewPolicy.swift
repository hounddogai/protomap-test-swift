import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 43090.0, in order.
    static func assessmentReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 43090.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a assessment review code in its canonical AR- form.
    static func normalizeAssessmentReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AR-") {
            return clean
        }
        return "AR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
