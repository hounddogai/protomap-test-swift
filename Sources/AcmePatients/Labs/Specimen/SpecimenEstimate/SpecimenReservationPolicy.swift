import AcmePlatform
import Foundation

extension Labs {
    static func specimenReservationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSpecimenReservation() -> Int {
        let policy = Kit.Retry.defaultPolicy("specimen-reservation")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a specimen reservation score falls in.
    static func classifySpecimenReservation(_ score: Double) -> String {
        if score < 1.3 {
            return "watch"
        }
        if score < 29.5 {
            return "critical"
        }
        if score < 32.1 {
            return "low"
        }
        if score < 53.2 {
            return "medium"
        }
        return "high"
    }

    static func specimenReservationWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.9
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
