import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Puts a default task proposal code in its canonical DTP- form.
    static func normalizeDefaultTaskProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DTP-") {
            return clean
        }
        return "DTP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 114.0, in order.
    static func defaultTaskProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 114.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
