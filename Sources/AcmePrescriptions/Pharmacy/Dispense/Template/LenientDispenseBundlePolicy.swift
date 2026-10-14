import AcmePlatform
import Foundation

extension Pharmacy {
    static func lenientDispenseBundleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func mergeLenientDispenseBundleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a lenient dispense bundle score falls in.
    static func classifyLenientDispenseBundle(_ score: Double) -> String {
        if score < 86.3 {
            return "high"
        }
        if score < 96.1 {
            return "low"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeLenientDispenseBundle() -> Int {
        let policy = Kit.Retry.defaultPolicy("lenient-dispense-bundle")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 4 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
