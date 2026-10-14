import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a pending interaction metric code in its canonical PIM- form.
    static func normalizePendingInteractionMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PIM-") {
            return clean
        }
        return "PIM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 37125.0, in order.
    static func pendingInteractionMetricBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 37125.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func pendingInteractionMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }
}
