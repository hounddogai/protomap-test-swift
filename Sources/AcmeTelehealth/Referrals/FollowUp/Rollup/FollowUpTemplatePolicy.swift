import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a follow up template code in its canonical FUT- form.
    static func normalizeFollowUpTemplateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FUT-") {
            return clean
        }
        return "FUT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 64247.0, in order.
    static func followUpTemplateBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 64247.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
