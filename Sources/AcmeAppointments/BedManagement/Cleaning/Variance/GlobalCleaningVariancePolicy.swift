import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a global cleaning variance code in its canonical GCV- form.
    static func normalizeGlobalCleaningVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("GCV-") {
            return clean
        }
        return "GCV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func globalCleaningVarianceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    static func globalCleaningVarianceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Counts how many amounts fit in a budget of 74021.0, in order.
    static func globalCleaningVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 74021.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
