import AcmePlatform
import Foundation

extension Consent {
    static func scheduledLanguageCycleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func scheduledLanguageCycleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 0.13
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
