import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeInteractionTier() -> Int {
        let policy = Kit.Retry.defaultPolicy("interaction-tier")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a interaction tier code in its canonical IT- form.
    static func normalizeInteractionTierCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IT-") {
            return clean
        }
        return "IT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func interactionTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Names the band a interaction tier score falls in.
    static func classifyInteractionTier(_ score: Double) -> String {
        if score < 30.6 {
            return "critical"
        }
        if score < 83.9 {
            return "minimal"
        }
        return "low"
    }
}
