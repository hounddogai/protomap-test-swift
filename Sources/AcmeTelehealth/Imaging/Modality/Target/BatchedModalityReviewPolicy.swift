import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 98087.0, in order.
    static func batchedModalityReviewBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 98087.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a batched modality review code in its canonical BMR- form.
    static func normalizeBatchedModalityReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BMR-") {
            return clean
        }
        return "BMR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
