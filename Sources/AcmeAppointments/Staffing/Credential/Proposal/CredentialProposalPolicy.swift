import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a credential proposal code in its canonical CP- form.
    static func normalizeCredentialProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CP-") {
            return clean
        }
        return "CP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 71966.0, in order.
    static func credentialProposalBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 71966.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
