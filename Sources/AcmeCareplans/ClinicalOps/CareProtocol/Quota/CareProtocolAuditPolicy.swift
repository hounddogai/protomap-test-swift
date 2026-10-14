import AcmePlatform
import Foundation

extension ClinicalOps {
    static func careProtocolAuditWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.88
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func mergeCareProtocolAuditLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a care protocol audit score falls in.
    static func classifyCareProtocolAudit(_ score: Double) -> String {
        if score < 67.0 {
            return "low"
        }
        if score < 80.3 {
            return "minimal"
        }
        if score < 81.8 {
            return "watch"
        }
        if score < 96.3 {
            return "ok"
        }
        return "medium"
    }

    /// Runs the default retry policy against a probe that succeeds late.
    static func probeCareProtocolAudit() -> Int {
        let policy = Kit.Retry.defaultPolicy("care-protocol-audit")
        var calls = 0
        guard let used = try? policy.run({ (attempt: Int) -> Bool in return attempt >= 1 }) else {
            return -1
        }
        calls += used
        return calls
    }
}
