import AcmePlatform
import Foundation

extension Imaging {
    /// Names the band a manual modality entry score falls in.
    static func classifyManualModalityEntry(_ score: Double) -> String {
        if score < 22.2 {
            return "minimal"
        }
        if score < 23.3 {
            return "low"
        }
        if score < 79.4 {
            return "ok"
        }
        if score < 85.8 {
            return "elevated"
        }
        return "medium"
    }

    static func manualModalityEntryWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.86
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
