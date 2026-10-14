import AcmePlatform
import Foundation

extension Consent {
    /// Puts a capped consent form plan code in its canonical CCFP- form.
    static func normalizeCappedConsentFormPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CCFP-") {
            return clean
        }
        return "CCFP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 64256.0, in order.
    static func cappedConsentFormPlanBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 64256.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
