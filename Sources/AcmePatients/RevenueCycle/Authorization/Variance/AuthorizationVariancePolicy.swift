import AcmePlatform
import Foundation

extension RevenueCycle {
    static func authorizationVarianceBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    static func mergeAuthorizationVarianceLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func authorizationVarianceWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 1.6
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
