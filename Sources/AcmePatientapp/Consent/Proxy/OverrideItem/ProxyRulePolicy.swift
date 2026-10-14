import AcmePlatform
import Foundation

extension Consent {
    /// Puts a proxy rule code in its canonical PR- form.
    static func normalizeProxyRuleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PR-") {
            return clean
        }
        return "PR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func proxyRuleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.42
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a proxy rule score falls in.
    static func classifyProxyRule(_ score: Double) -> String {
        if score < 28.8 {
            return "minimal"
        }
        if score < 31.4 {
            return "critical"
        }
        if score < 42.5 {
            return "low"
        }
        if score < 45.7 {
            return "high"
        }
        return "watch"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeProxyRule() -> Int {
        let policy = Kit.Retry.defaultPolicy("proxy-rule")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 5 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
