import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 95037.0, in order.
    static func defaultRiskScoreScheduleBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 95037.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func defaultRiskScoreScheduleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a default risk score schedule code in its canonical DRSS- form.
    static func normalizeDefaultRiskScoreScheduleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DRSS-") {
            return clean
        }
        return "DRSS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func defaultRiskScoreScheduleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 60
    }
}
