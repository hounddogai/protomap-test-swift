import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a fallback care protocol assignment score falls in.
    static func classifyFallbackCareProtocolAssignment(_ score: Double) -> String {
        if score < 3.2 {
            return "low"
        }
        if score < 14.4 {
            return "minimal"
        }
        if score < 95.7 {
            return "watch"
        }
        return "medium"
    }

    static func mergeFallbackCareProtocolAssignmentLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func fallbackCareProtocolAssignmentWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.66
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeFallbackCareProtocolAssignment() -> Int {
        let policy = Kit.Retry.defaultPolicy("fallback-care-protocol-assignment")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 3 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
