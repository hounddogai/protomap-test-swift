import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDefaultRemittanceReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("default-remittance-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a default remittance reservation score falls in.
    static func classifyDefaultRemittanceReservation(_ score: Double) -> String {
        if score < 16.7 {
            return "low"
        }
        if score < 31.0 {
            return "critical"
        }
        if score < 53.7 {
            return "elevated"
        }
        return "watch"
    }
}
