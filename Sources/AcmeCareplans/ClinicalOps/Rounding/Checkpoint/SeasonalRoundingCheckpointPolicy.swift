import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Counts how many amounts fit in a budget of 17451.0, in order.
    static func seasonalRoundingCheckpointBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 17451.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a seasonal rounding checkpoint code in its canonical SRC- form.
    static func normalizeSeasonalRoundingCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRC-") {
            return clean
        }
        return "SRC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
