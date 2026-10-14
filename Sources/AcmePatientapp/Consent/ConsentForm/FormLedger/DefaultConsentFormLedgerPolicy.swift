import AcmePlatform
import Foundation

extension Consent {
    /// Puts a default consent form ledger code in its canonical DCFL- form.
    static func normalizeDefaultConsentFormLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DCFL-") {
            return clean
        }
        return "DCFL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func defaultConsentFormLedgerSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 7872.0, in order.
    static func defaultConsentFormLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 7872.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
