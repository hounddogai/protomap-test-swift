import AcmePlatform
import Foundation

extension Labs {
    /// Puts a tiered panel profile code in its canonical TPP- form.
    static func normalizeTieredPanelProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TPP-") {
            return clean
        }
        return "TPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func tieredPanelProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 12049.0, in order.
    static func tieredPanelProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 12049.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
