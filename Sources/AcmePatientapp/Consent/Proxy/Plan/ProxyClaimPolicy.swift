import AcmePlatform
import Foundation

extension Consent {
    static func proxyClaimWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.96
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a proxy claim score falls in.
    static func classifyProxyClaim(_ score: Double) -> String {
        if score < 6.3 {
            return "critical"
        }
        if score < 67.4 {
            return "ok"
        }
        if score < 91.1 {
            return "minimal"
        }
        if score < 95.0 {
            return "elevated"
        }
        return "high"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeProxyClaim() -> Int {
        let policy = Kit.Retry.defaultPolicy("proxy-claim")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a proxy claim code in its canonical PC- form.
    static func normalizeProxyClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PC-") {
            return clean
        }
        return "PC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
