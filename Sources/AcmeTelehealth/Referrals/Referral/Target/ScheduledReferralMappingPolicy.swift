import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 48245.0, in order.
    static func scheduledReferralMappingBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 48245.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Puts a scheduled referral mapping code in its canonical SRM- form.
    static func normalizeScheduledReferralMappingCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRM-") {
            return clean
        }
        return "SRM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func scheduledReferralMappingBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func scheduledReferralMappingWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 1.22
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
