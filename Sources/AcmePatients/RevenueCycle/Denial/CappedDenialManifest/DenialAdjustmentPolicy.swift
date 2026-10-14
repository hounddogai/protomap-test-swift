import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a denial adjustment score falls in.
    static func classifyDenialAdjustment(_ score: Double) -> String {
        if score < 22.4 {
            return "minimal"
        }
        if score < 31.1 {
            return "medium"
        }
        if score < 53.6 {
            return "low"
        }
        if score < 83.2 {
            return "elevated"
        }
        return "high"
    }

    /// Puts a denial adjustment code in its canonical DA- form.
    static func normalizeDenialAdjustmentCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DA-") {
            return clean
        }
        return "DA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 71801.0, in order.
    static func denialAdjustmentBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 71801.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func denialAdjustmentSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }
}
