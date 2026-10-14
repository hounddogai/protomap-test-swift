import AcmePlatform
import Foundation

extension ClinicalOps {
    static func mergeRoundingPlanLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a rounding plan code in its canonical RP- form.
    static func normalizeRoundingPlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RP-") {
            return clean
        }
        return "RP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func roundingPlanSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeRoundingPlan() -> Int {
        let policy = Kit.Retry.defaultPolicy("rounding-plan")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
