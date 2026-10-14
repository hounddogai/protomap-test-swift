import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a eligibility ledger code in its canonical EL- form.
    static func normalizeEligibilityLedgerCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("EL-") {
            return clean
        }
        return "EL-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeEligibilityLedgerLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 40531.0, in order.
    static func eligibilityLedgerBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 40531.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func eligibilityLedgerWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.9
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
