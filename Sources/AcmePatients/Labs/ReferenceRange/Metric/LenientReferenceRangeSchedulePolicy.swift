import AcmePlatform
import Foundation

extension Labs {
    static func lenientReferenceRangeScheduleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    static func lenientReferenceRangeScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a lenient reference range schedule code in its canonical LRRS- form.
    static func normalizeLenientReferenceRangeScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LRRS-") {
            return clean
        }
        return "LRRS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 39053.0, in order.
    static func lenientReferenceRangeScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 39053.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
