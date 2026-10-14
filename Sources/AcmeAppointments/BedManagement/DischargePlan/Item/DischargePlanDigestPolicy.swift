import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a discharge plan digest code in its canonical DPD- form.
    static func normalizeDischargePlanDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DPD-") {
            return clean
        }
        return "DPD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 17617.0, in order.
    static func dischargePlanDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 17617.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func dischargePlanDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    static func dischargePlanDigestWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.34
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
