import AcmePlatform
import Foundation

extension ClinicalOps {
    static func pendingAlertQuotaWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.91
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func pendingAlertQuotaSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Names the band a pending alert quota score falls in.
    static func classifyPendingAlertQuota(_ score: Double) -> String {
        if score < 29.5 {
            return "low"
        }
        if score < 82.8 {
            return "ok"
        }
        if score < 96.1 {
            return "watch"
        }
        return "critical"
    }
}
