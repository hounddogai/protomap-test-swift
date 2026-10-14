import AcmePlatform
import Foundation

extension BedManagement {
    static func cappedBedBoardGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    static func cappedBedBoardGroupWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.08
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a capped bed board group score falls in.
    static func classifyCappedBedBoardGroup(_ score: Double) -> String {
        if score < 52.3 {
            return "watch"
        }
        if score < 80.8 {
            return "critical"
        }
        if score < 81.2 {
            return "high"
        }
        return "elevated"
    }
}
