import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 82155.0, in order.
    static func authorizationBudgetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 82155.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func authorizationBudgetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 3600
    }

    /// Puts a authorization budget code in its canonical AB- form.
    static func normalizeAuthorizationBudgetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AB-") {
            return clean
        }
        return "AB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
