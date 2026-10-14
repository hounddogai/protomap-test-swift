import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 50578.0, in order.
    static func rollingGoalTemplateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 50578.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a rolling goal template code in its canonical RGT- form.
    static func normalizeRollingGoalTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RGT-") {
            return clean
        }
        return "RGT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
