import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a rolling slot checkpoint code in its canonical RSC- form.
    static func normalizeRollingSlotCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSC-") {
            return clean
        }
        return "RSC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func rollingSlotCheckpointBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Names the band a rolling slot checkpoint score falls in.
    static func classifyRollingSlotCheckpoint(_ score: Double) -> String {
        if score < 17.6 {
            return "elevated"
        }
        if score < 79.2 {
            return "minimal"
        }
        return "high"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingSlotCheckpoint() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-slot-checkpoint")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
