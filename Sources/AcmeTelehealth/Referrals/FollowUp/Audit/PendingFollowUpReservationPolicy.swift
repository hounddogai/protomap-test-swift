import AcmePlatform
import Foundation

extension Referrals {
    static func mergePendingFollowUpReservationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Counts how many amounts fit in a budget of 835.0, in order.
    static func pendingFollowUpReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 835.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a pending follow up reservation code in its canonical PFUR- form.
    static func normalizePendingFollowUpReservationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PFUR-") {
            return clean
        }
        return "PFUR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func pendingFollowUpReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
