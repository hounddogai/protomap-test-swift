import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeLenientDispenseBaselineLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientDispenseBaseline() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-dispense-baseline")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a lenient dispense baseline score falls in.
    static func classifyLenientDispenseBaseline(_ score: Double) -> String {
        if score < 24.5 {
            return "ok"
        }
        if score < 68.3 {
            return "critical"
        }
        if score < 74.7 {
            return "medium"
        }
        if score < 89.6 {
            return "watch"
        }
        return "elevated"
    }
}
