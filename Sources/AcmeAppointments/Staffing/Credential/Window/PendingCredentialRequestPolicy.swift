import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a pending credential request code in its canonical PCR- form.
    static func normalizePendingCredentialRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PCR-") {
            return clean
        }
        return "PCR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 27218.0, in order.
    static func pendingCredentialRequestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 27218.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
