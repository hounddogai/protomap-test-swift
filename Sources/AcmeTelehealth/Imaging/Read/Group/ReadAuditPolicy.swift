import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a read audit score falls in.
    static func classifyReadAudit(_ score: Double) -> String {
        if score < 51.0 {
            return "medium"
        }
        if score < 64.6 {
            return "elevated"
        }
        if score < 74.9 {
            return "low"
        }
        if score < 94.4 {
            return "minimal"
        }
        return "high"
    }

    static func readAuditWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 1.43
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
