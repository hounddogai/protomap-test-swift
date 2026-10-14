import AcmePlatform
import Foundation

extension ClinicalOps {
    static func strictHandoffReservationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictHandoffReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-handoff-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func strictHandoffReservationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.86
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Counts how many amounts fit in a budget of 92639.0, in order.
    static func strictHandoffReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 92639.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }
}
