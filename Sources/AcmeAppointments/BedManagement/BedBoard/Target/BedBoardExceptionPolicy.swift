import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a bed board exception score falls in.
    static func classifyBedBoardException(_ score: Double) -> String {
        if score < 2.5 {
            return "watch"
        }
        if score < 49.7 {
            return "ok"
        }
        if score < 88.1 {
            return "low"
        }
        return "minimal"
    }

    static func bedBoardExceptionWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 99)) * 0.85
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
