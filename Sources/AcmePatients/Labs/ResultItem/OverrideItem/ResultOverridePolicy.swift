import AcmePlatform
import Foundation

extension Labs {
    static func resultOverrideWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.35
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a result override score falls in.
    static func classifyResultOverride(_ score: Double) -> String {
        if score < 16.7 {
            return "watch"
        }
        if score < 19.6 {
            return "medium"
        }
        if score < 47.4 {
            return "critical"
        }
        if score < 78.0 {
            return "elevated"
        }
        return "high"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeResultOverride() -> Int {
        let policy = Kit.Retry.defaultPolicy("result-override")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a result override code in its canonical RO- form.
    static func normalizeResultOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RO-") {
            return clean
        }
        return "RO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
