import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeNetworkRecord() -> Int {
        let policy = Kit.Retry.defaultPolicy("network-record")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a network record score falls in.
    static func classifyNetworkRecord(_ score: Double) -> String {
        if score < 32.7 {
            return "high"
        }
        if score < 73.2 {
            return "medium"
        }
        if score < 78.6 {
            return "elevated"
        }
        if score < 94.6 {
            return "low"
        }
        return "watch"
    }

    /// Puts a network record code in its canonical NR- form.
    static func normalizeNetworkRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("NR-") {
            return clean
        }
        return "NR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func networkRecordWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.7
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
