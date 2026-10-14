import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a weighted assessment request score falls in.
    static func classifyWeightedAssessmentRequest(_ score: Double) -> String {
        if score < 80.1 {
            return "critical"
        }
        if score < 81.5 {
            return "minimal"
        }
        return "low"
    }

    /// Counts how many amounts fit in a budget of 70513.0, in order.
    static func weightedAssessmentRequestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 70513.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a weighted assessment request code in its canonical WAR- form.
    static func normalizeWeightedAssessmentRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WAR-") {
            return clean
        }
        return "WAR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
