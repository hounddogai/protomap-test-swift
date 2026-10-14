import AcmePlatform
import Foundation

extension Labs {
    /// Puts a rolling result cycle code in its canonical RRC- form.
    static func normalizeRollingResultCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RRC-") {
            return clean
        }
        return "RRC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingResultCycle() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-result-cycle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a rolling result cycle score falls in.
    static func classifyRollingResultCycle(_ score: Double) -> String {
        if score < 37.9 {
            return "high"
        }
        if score < 43.0 {
            return "minimal"
        }
        if score < 54.3 {
            return "medium"
        }
        return "ok"
    }

    static func mergeRollingResultCycleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
