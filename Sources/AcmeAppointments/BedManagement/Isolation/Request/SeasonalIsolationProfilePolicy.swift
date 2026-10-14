import AcmePlatform
import Foundation

extension BedManagement {
    /// Counts how many amounts fit in a budget of 23308.0, in order.
    static func seasonalIsolationProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 23308.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a seasonal isolation profile code in its canonical SIP- form.
    static func normalizeSeasonalIsolationProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SIP-") {
            return clean
        }
        return "SIP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func seasonalIsolationProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    static func seasonalIsolationProfileBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
