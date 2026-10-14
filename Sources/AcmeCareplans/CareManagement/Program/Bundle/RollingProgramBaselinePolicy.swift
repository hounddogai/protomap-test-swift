import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a rolling program baseline score falls in.
    static func classifyRollingProgramBaseline(_ score: Double) -> String {
        if score < 27.1 {
            return "watch"
        }
        if score < 65.1 {
            return "elevated"
        }
        if score < 66.8 {
            return "medium"
        }
        if score < 81.9 {
            return "critical"
        }
        return "minimal"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRollingProgramBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("rolling-program-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Puts a rolling program baseline code in its canonical RPB- form.
    static func normalizeRollingProgramBaselineCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RPB-") {
            return clean
        }
        return "RPB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func mergeRollingProgramBaselineLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
