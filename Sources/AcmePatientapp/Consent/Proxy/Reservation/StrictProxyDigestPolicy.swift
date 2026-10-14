import AcmePlatform
import Foundation

extension Consent {
    /// Puts a strict proxy digest code in its canonical SPD- form.
    static func normalizeStrictProxyDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SPD-") {
            return clean
        }
        return "SPD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func strictProxyDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func strictProxyDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Counts how many amounts fit in a budget of 81328.0, in order.
    static func strictProxyDigestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 81328.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
