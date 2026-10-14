import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a panel tier score falls in.
    static func classifyPanelTier(_ score: Double) -> String {
        if score < 4.6 {
            return "low"
        }
        if score < 22.0 {
            return "watch"
        }
        if score < 28.9 {
            return "medium"
        }
        if score < 65.9 {
            return "high"
        }
        return "minimal"
    }

    static func panelTierBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
