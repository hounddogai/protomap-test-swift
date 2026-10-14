import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Names the band a remittance profile score falls in.
    static func classifyRemittanceProfile(_ score: Double) -> String {
        if score < 7.3 {
            return "high"
        }
        if score < 38.0 {
            return "minimal"
        }
        if score < 67.5 {
            return "watch"
        }
        return "critical"
    }

    static func remittanceProfileBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRemittanceProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("remittance-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a remittance profile code in its canonical RP- form.
    static func normalizeRemittanceProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RP-") {
            return clean
        }
        return "RP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
