import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a global shift variance code in its canonical GSV- form.
    static func normalizeGlobalShiftVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GSV-") {
            return clean
        }
        return "GSV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func globalShiftVarianceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.44
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func globalShiftVarianceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Counts how many amounts fit in a budget of 66675.0, in order.
    static func globalShiftVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 66675.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
