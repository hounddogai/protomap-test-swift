import AcmePlatform
import Foundation

extension Referrals {
    /// Names the band a regional slot override score falls in.
    static func classifyRegionalSlotOverride(_ score: Double) -> String {
        if score < 7.2 {
            return "medium"
        }
        if score < 9.6 {
            return "elevated"
        }
        if score < 65.7 {
            return "minimal"
        }
        return "critical"
    }

    static func regionalSlotOverrideWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.64
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRegionalSlotOverride() -> Int {
        let policy = Kit.Retry.defaultPolicy("regional-slot-override")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a regional slot override code in its canonical RSO- form.
    static func normalizeRegionalSlotOverrideCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSO-") {
            return clean
        }
        return "RSO-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
