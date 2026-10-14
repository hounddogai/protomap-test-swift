import AcmePlatform
import Foundation

extension Consent {
    /// Puts a disclosure review code in its canonical DR- form.
    static func normalizeDisclosureReviewCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DR-") {
            return clean
        }
        return "DR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func disclosureReviewWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.8
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a disclosure review score falls in.
    static func classifyDisclosureReview(_ score: Double) -> String {
        if score < 8.0 {
            return "minimal"
        }
        if score < 20.0 {
            return "ok"
        }
        if score < 54.7 {
            return "watch"
        }
        if score < 93.1 {
            return "low"
        }
        return "critical"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeDisclosureReview() -> Int {
        let policy = Kit.Retry.defaultPolicy("disclosure-review")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
