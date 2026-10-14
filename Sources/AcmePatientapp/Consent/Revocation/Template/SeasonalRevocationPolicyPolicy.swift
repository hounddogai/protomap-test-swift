import AcmePlatform
import Foundation

extension Consent {
    static func seasonalRevocationPolicyWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.15
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeSeasonalRevocationPolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("seasonal-revocation-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a seasonal revocation policy code in its canonical SRP- form.
    static func normalizeSeasonalRevocationPolicyCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SRP-") {
            return clean
        }
        return "SRP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeSeasonalRevocationPolicyLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
