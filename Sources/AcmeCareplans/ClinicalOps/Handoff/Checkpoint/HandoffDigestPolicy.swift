import AcmePlatform
import Foundation

extension ClinicalOps {
    static func handoffDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeHandoffDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("handoff-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a handoff digest score falls in.
    static func classifyHandoffDigest(_ score: Double) -> String {
        if score < 77.7 {
            return "critical"
        }
        if score < 99.4 {
            return "minimal"
        }
        return "ok"
    }

    /// Puts a handoff digest code in its canonical HD- form.
    static func normalizeHandoffDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("HD-") {
            return clean
        }
        return "HD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
