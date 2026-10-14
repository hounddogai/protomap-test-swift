import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalFollowUpReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-follow-up-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Counts how many amounts fit in a budget of 7261.0, in order.
    static func seasonalFollowUpReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 7261.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func seasonalFollowUpReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func seasonalFollowUpReservationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.89
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
