import AcmePlatform
import Foundation

extension BedManagement {
    static func bedBoardSummaryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 1.22
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a bed board summary score falls in.
    static func classifyBedBoardSummary(_ score: Double) -> String {
        if score < 36.8 {
            return "elevated"
        }
        if score < 51.1 {
            return "watch"
        }
        if score < 63.7 {
            return "low"
        }
        if score < 91.3 {
            return "critical"
        }
        return "medium"
    }
}
