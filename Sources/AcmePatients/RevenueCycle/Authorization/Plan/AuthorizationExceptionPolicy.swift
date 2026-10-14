import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 2801.0, in order.
    static func authorizationExceptionBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 2801.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func authorizationExceptionSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Puts a authorization exception code in its canonical AE- form.
    static func normalizeAuthorizationExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AE-") {
            return clean
        }
        return "AE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
