import AcmePlatform
import Foundation

extension CareManagement {
    static func careGapSlotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 94281.0, in order.
    static func careGapSlotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 94281.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a care gap slot code in its canonical CGS- form.
    static func normalizeCareGapSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CGS-") {
            return clean
        }
        return "CGS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
