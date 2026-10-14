import AcmePlatform
import Foundation

extension Referrals {
    /// Counts how many amounts fit in a budget of 63953.0, in order.
    static func seasonalSlotNoticeBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 63953.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func seasonalSlotNoticeWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.96
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func seasonalSlotNoticeBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    /// Puts a seasonal slot notice code in its canonical SSN- form.
    static func normalizeSeasonalSlotNoticeCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SSN-") {
            return clean
        }
        return "SSN-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
