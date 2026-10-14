import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 38482.0, in order.
    static func adaptiveProgramBaselineBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 38482.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a adaptive program baseline code in its canonical APB- form.
    static func normalizeAdaptiveProgramBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("APB-") {
            return clean
        }
        return "APB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func adaptiveProgramBaselineSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }

    static func adaptiveProgramBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
