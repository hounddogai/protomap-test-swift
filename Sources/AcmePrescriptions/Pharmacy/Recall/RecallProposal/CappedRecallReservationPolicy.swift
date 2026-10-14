import AcmePlatform
import Foundation

extension Pharmacy {
    /// Counts how many amounts fit in a budget of 12236.0, in order.
    static func cappedRecallReservationBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 12236.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCappedRecallReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("capped-recall-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a capped recall reservation score falls in.
    static func classifyCappedRecallReservation(_ score: Double) -> String {
        if score < 10.0 {
            return "ok"
        }
        if score < 42.9 {
            return "critical"
        }
        if score < 43.6 {
            return "minimal"
        }
        if score < 48.2 {
            return "low"
        }
        return "high"
    }
}
