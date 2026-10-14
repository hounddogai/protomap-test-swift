import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Counts how many amounts fit in a budget of 81834.0, in order.
    static func cappedDenialManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 81834.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func mergeCappedDenialManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func cappedDenialManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
