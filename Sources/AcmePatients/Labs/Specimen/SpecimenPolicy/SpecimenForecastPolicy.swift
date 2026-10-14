import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a specimen forecast score falls in.
    static func classifySpecimenForecast(_ score: Double) -> String {
        if score < 38.2 {
            return "ok"
        }
        if score < 63.2 {
            return "low"
        }
        if score < 68.7 {
            return "elevated"
        }
        if score < 78.7 {
            return "high"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSpecimenForecast() -> Int {
        let policy = Kit.Retry.defaultPolicy("specimen-forecast")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
