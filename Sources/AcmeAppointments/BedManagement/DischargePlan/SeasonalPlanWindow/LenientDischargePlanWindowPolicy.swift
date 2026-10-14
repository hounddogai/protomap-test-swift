import AcmePlatform
import Foundation

extension BedManagement {
    static func lenientDischargePlanWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Puts a lenient discharge plan window code in its canonical LDPW- form.
    static func normalizeLenientDischargePlanWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LDPW-") {
            return clean
        }
        return "LDPW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func lenientDischargePlanWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.12
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 54076.0, in order.
    static func lenientDischargePlanWindowBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 54076.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
