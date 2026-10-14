import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientChargeDigest() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-charge-digest")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 2 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a lenient charge digest code in its canonical LCD- form.
    static func normalizeLenientChargeDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LCD-") {
            return clean
        }
        return "LCD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a lenient charge digest score falls in.
    static func classifyLenientChargeDigest(_ score: Double) -> String {
        if score < 33.1 {
            return "critical"
        }
        if score < 41.8 {
            return "low"
        }
        if score < 44.7 {
            return "medium"
        }
        if score < 98.0 {
            return "high"
        }
        return "minimal"
    }

    static func mergeLenientChargeDigestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
