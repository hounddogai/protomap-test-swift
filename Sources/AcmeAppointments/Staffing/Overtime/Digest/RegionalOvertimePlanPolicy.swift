import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a regional overtime plan code in its canonical ROP- form.
    static func normalizeRegionalOvertimePlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("ROP-") {
            return clean
        }
        return "ROP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func regionalOvertimePlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.92
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func regionalOvertimePlanSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 26352.0, in order.
    static func regionalOvertimePlanBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 26352.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
