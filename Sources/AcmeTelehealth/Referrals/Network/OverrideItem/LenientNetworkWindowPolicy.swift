import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a lenient network window code in its canonical LNW- form.
    static func normalizeLenientNetworkWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LNW-") {
            return clean
        }
        return "LNW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func lenientNetworkWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientNetworkWindow() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-network-window")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func lenientNetworkWindowWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.55
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
