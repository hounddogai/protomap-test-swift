import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 15262.0, in order.
    static func rollingAssessmentNoticeBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 15262.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a rolling assessment notice code in its canonical RAN- form.
    static func normalizeRollingAssessmentNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RAN-") {
            return clean
        }
        return "RAN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
