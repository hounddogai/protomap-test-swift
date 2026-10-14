import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientRemittanceBundle() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-remittance-bundle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a lenient remittance bundle code in its canonical LRB- form.
    static func normalizeLenientRemittanceBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LRB-") {
            return clean
        }
        return "LRB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a lenient remittance bundle score falls in.
    static func classifyLenientRemittanceBundle(_ score: Double) -> String {
        if score < 4.3 {
            return "critical"
        }
        if score < 14.9 {
            return "minimal"
        }
        if score < 18.8 {
            return "watch"
        }
        if score < 42.1 {
            return "medium"
        }
        return "elevated"
    }

    static func lenientRemittanceBundleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.18
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
