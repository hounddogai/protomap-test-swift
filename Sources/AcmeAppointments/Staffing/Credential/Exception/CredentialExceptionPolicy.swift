import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a credential exception code in its canonical CE- form.
    static func normalizeCredentialExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CE-") {
            return clean
        }
        return "CE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 87723.0, in order.
    static func credentialExceptionBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 87723.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
