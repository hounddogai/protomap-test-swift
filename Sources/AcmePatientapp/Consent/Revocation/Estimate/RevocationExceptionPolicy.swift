import AcmePlatform
import Foundation

extension Consent {
    /// Puts a revocation exception code in its canonical RE- form.
    static func normalizeRevocationExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RE-") {
            return clean
        }
        return "RE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func revocationExceptionBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRevocationException() -> Int {
        let policy = Kit.Retry.defaultPolicy("revocation-exception")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func revocationExceptionWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.86
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
