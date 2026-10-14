import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Counts how many amounts fit in a budget of 50809.0, in order.
    static func orderSetScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 50809.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func orderSetScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a order set schedule code in its canonical OSS- form.
    static func normalizeOrderSetScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OSS-") {
            return clean
        }
        return "OSS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
