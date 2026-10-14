import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the default retry policy against a probe that succeeds late.
    static func probeHandoffAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("handoff-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }

    /// Names the band a handoff audit score falls in.
    static func classifyHandoffAudit(_ score: Double) -> String {
        if score < 37.0 {
            return "ok"
        }
        if score < 73.6 {
            return "critical"
        }
        if score < 93.5 {
            return "medium"
        }
        return "low"
    }

    static func handoffAuditWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 2.42
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeHandoffAuditLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
