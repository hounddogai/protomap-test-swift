import AcmePlatform
import Foundation

extension CareManagement {
    static func goalMappingSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 3600
    }

    static func goalMappingWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.74
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a goal mapping score falls in.
    static func classifyGoalMapping(_ score: Double) -> String {
        if score < 80.9 {
            return "medium"
        }
        if score < 86.4 {
            return "elevated"
        }
        return "ok"
    }
}
