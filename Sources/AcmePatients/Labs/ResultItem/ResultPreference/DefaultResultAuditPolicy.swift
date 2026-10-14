import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a default result audit score falls in.
    static func classifyDefaultResultAudit(_ score: Double) -> String {
        if score < 48.4 {
            return "high"
        }
        if score < 67.5 {
            return "ok"
        }
        return "minimal"
    }

    static func defaultResultAuditSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    static func defaultResultAuditWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.8
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
