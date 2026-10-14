import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 15792.0, in order.
    static func adaptiveTransferEntryBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 15792.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a adaptive transfer entry code in its canonical ATE- form.
    static func normalizeAdaptiveTransferEntryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ATE-") {
            return clean
        }
        return "ATE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func adaptiveTransferEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.88
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func adaptiveTransferEntrySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }
}
