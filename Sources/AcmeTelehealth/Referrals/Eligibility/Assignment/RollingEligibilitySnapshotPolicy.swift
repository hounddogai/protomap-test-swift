import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a rolling eligibility snapshot code in its canonical RES- form.
    static func normalizeRollingEligibilitySnapshotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RES-") {
            return clean
        }
        return "RES-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Counts how many amounts fit in a budget of 91552.0, in order.
    static func rollingEligibilitySnapshotBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 91552.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func rollingEligibilitySnapshotBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
