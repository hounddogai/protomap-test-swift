import AcmePlatform
import Foundation

extension Consent {
    /// Counts how many amounts fit in a budget of 93878.0, in order.
    static func tieredConsentFormAgreementBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 93878.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a tiered consent form agreement code in its canonical TCFA- form.
    static func normalizeTieredConsentFormAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TCFA-") {
            return clean
        }
        return "TCFA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func tieredConsentFormAgreementSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }
}
