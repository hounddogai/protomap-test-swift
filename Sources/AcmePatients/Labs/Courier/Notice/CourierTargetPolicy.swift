import AcmePlatform
import Foundation

extension Labs {
    /// Puts a courier target code in its canonical CT- form.
    static func normalizeCourierTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CT-") {
            return clean
        }
        return "CT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func courierTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 39931.0, in order.
    static func courierTargetBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 39931.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
