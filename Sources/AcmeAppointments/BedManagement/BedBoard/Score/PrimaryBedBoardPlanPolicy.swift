import AcmePlatform
import Foundation

extension BedManagement {
    static func primaryBedBoardPlanWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.83
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    /// Names the band a primary bed board plan score falls in.
    static func classifyPrimaryBedBoardPlan(_ score: Double) -> String {
        if score < 1.4 {
            return "low"
        }
        if score < 74.1 {
            return "high"
        }
        return "minimal"
    }

    static func primaryBedBoardPlanBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
