import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptivePriorityClaim() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-priority-claim")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a adaptive priority claim score falls in.
    static func classifyAdaptivePriorityClaim(_ score: Double) -> String {
        if score < 6.8 {
            return "ok"
        }
        if score < 40.2 {
            return "low"
        }
        if score < 45.4 {
            return "watch"
        }
        return "minimal"
    }

    static func adaptivePriorityClaimWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.81
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Puts a adaptive priority claim code in its canonical APC- form.
    static func normalizeAdaptivePriorityClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("APC-") {
            return clean
        }
        return "APC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
