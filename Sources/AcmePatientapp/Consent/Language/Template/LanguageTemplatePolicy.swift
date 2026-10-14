import AcmePlatform
import Foundation

extension Consent {
    static func languageTemplateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    static func languageTemplateWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 9)) * 2.02
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
