import AcmePlatform
import Foundation

extension BedManagement {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeAdaptiveIsolationBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("adaptive-isolation-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a adaptive isolation baseline code in its canonical AIB- form.
    static func normalizeAdaptiveIsolationBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AIB-") {
            return clean
        }
        return "AIB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a adaptive isolation baseline score falls in.
    static func classifyAdaptiveIsolationBaseline(_ score: Double) -> String {
        if score < 40.7 {
            return "critical"
        }
        if score < 64.5 {
            return "low"
        }
        return "minimal"
    }
}
