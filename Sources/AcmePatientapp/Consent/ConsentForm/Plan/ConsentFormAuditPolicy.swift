import AcmePlatform
import Foundation

extension Consent {
    /// Puts a consent form audit code in its canonical CFA- form.
    static func normalizeConsentFormAuditCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CFA-") {
            return clean
        }
        return "CFA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 14701.0, in order.
    static func consentFormAuditBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 14701.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
