import AcmePlatform
import Foundation

extension Consent {
    static func witnessPlanSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Puts a witness plan code in its canonical WP- form.
    static func normalizeWitnessPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WP-") {
            return clean
        }
        return "WP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func witnessPlanBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Counts how many amounts fit in a budget of 70283.0, in order.
    static func witnessPlanBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 70283.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
