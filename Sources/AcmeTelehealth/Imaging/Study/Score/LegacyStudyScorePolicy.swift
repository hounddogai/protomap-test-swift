import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a legacy study score score falls in.
    static func classifyLegacyStudyScore(_ score: Double) -> String {
        if score < 69.0 {
            return "high"
        }
        if score < 89.2 {
            return "ok"
        }
        return "medium"
    }

    static func legacyStudyScoreWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 0.74
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
