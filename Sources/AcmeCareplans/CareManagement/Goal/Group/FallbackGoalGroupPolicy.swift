import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a fallback goal group code in its canonical FGG- form.
    static func normalizeFallbackGoalGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FGG-") {
            return clean
        }
        return "FGG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 51576.0, in order.
    static func fallbackGoalGroupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 51576.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
