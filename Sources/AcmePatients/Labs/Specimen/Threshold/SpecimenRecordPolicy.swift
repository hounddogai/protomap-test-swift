import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a specimen record score falls in.
    static func classifySpecimenRecord(_ score: Double) -> String {
        if score < 6.4 {
            return "ok"
        }
        if score < 22.3 {
            return "critical"
        }
        if score < 62.9 {
            return "high"
        }
        if score < 82.2 {
            return "minimal"
        }
        return "low"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSpecimenRecord() -> Int {
        let policy = Kit.Retry.defaultPolicy("specimen-record")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
