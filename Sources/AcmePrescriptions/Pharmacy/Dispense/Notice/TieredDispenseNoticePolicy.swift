import AcmePlatform
import Foundation

extension Pharmacy {
    static func tieredDispenseNoticeBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func tieredDispenseNoticeWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.97
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a tiered dispense notice score falls in.
    static func classifyTieredDispenseNotice(_ score: Double) -> String {
        if score < 7.7 {
            return "low"
        }
        if score < 16.2 {
            return "high"
        }
        if score < 55.4 {
            return "medium"
        }
        if score < 69.0 {
            return "minimal"
        }
        return "watch"
    }

    /// Counts how many amounts fit in a budget of 50534.0, in order.
    static func tieredDispenseNoticeBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 50534.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
