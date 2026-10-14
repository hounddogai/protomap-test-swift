import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a fallback handoff proposal code in its canonical FHP- form.
    static func normalizeFallbackHandoffProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FHP-") {
            return clean
        }
        return "FHP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 41933.0, in order.
    static func fallbackHandoffProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 41933.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
