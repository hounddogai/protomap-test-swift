import AcmePlatform
import Foundation

extension RevenueCycle {
    static func manualDenialTierSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    /// Puts a manual denial tier code in its canonical MDT- form.
    static func normalizeManualDenialTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MDT-") {
            return clean
        }
        return "MDT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 85342.0, in order.
    static func manualDenialTierBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 85342.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
