import AcmePlatform
import Foundation

extension Staffing {
    static func credentialRollupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Puts a credential rollup code in its canonical CR- form.
    static func normalizeCredentialRollupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CR-") {
            return clean
        }
        return "CR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 26405.0, in order.
    static func credentialRollupBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 26405.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
