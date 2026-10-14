import AcmePlatform
import Foundation

extension Pharmacy {
    /// Names the band a strict formulary policy score falls in.
    static func classifyStrictFormularyPolicy(_ score: Double) -> String {
        if score < 26.2 {
            return "low"
        }
        if score < 32.8 {
            return "minimal"
        }
        if score < 67.2 {
            return "medium"
        }
        return "elevated"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeStrictFormularyPolicy() -> Int {
        let policy = Kit.Retry.defaultPolicy("strict-formulary-policy")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }

    static func mergeStrictFormularyPolicyLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func strictFormularyPolicySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }
}
