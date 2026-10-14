import AcmePlatform
import Foundation

extension Staffing {
    static func weightedCredentialProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    static func weightedCredentialProfileBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a weighted credential profile code in its canonical WCP- form.
    static func normalizeWeightedCredentialProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WCP-") {
            return clean
        }
        return "WCP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 6028.0, in order.
    static func weightedCredentialProfileBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 6028.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
