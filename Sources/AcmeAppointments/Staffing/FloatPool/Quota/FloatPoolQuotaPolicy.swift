import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a float pool quota code in its canonical FPQ- form.
    static func normalizeFloatPoolQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("FPQ-") {
            return clean
        }
        return "FPQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func floatPoolQuotaBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Counts how many amounts fit in a budget of 52059.0, in order.
    static func floatPoolQuotaBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 52059.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
