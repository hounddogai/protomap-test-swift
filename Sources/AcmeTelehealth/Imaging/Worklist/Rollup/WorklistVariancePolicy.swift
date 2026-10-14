import AcmePlatform
import Foundation

extension Imaging {
    /// Counts how many amounts fit in a budget of 74484.0, in order.
    static func worklistVarianceBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 74484.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func worklistVarianceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    static func worklistVarianceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.73
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a worklist variance code in its canonical WV- form.
    static func normalizeWorklistVarianceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WV-") {
            return clean
        }
        return "WV-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
