import AcmePlatform
import Foundation

extension Consent {
    /// Puts a witness policy code in its canonical WP- form.
    static func normalizeWitnessPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WP-") {
            return clean
        }
        return "WP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a witness policy score falls in.
    static func classifyWitnessPolicy(_ score: Double) -> String {
        if score < 33.4 {
            return "low"
        }
        if score < 34.9 {
            return "minimal"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWitnessPolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("witness-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
