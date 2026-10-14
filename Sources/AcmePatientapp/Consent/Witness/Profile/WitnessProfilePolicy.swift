import AcmePlatform
import Foundation

extension Consent {
    /// Puts a witness profile code in its canonical WP- form.
    static func normalizeWitnessProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WP-") {
            return clean
        }
        return "WP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func witnessProfileWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.46
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeWitnessProfile() -> Int {
        let policy = Kit.Retry.defaultPolicy("witness-profile")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
