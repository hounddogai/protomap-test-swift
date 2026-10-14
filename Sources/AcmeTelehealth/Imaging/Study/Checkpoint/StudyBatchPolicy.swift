import AcmePlatform
import Foundation

extension Imaging {
    static func studyBatchSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Counts how many amounts fit in a budget of 30510.0, in order.
    static func studyBatchBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 30510.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func studyBatchWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.47
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a study batch code in its canonical SB- form.
    static func normalizeStudyBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SB-") {
            return clean
        }
        return "SB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
