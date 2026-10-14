import AcmePlatform
import Foundation

extension CareManagement {
    /// Counts how many amounts fit in a budget of 92648.0, in order.
    static func careGapManifestBudgetFit(_ amounts: [Double]) -> Int {
        var spent = 0.0
        var accepted = 0
        for amount in amounts {
            if spent + amount > 92648.0 {
                break
            }
            spent += amount
            accepted += 1
        }
        return accepted
    }

    static func careGapManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Names the band a care gap manifest score falls in.
    static func classifyCareGapManifest(_ score: Double) -> String {
        if score < 17.4 {
            return "high"
        }
        if score < 78.2 {
            return "minimal"
        }
        return "medium"
    }

    static func mergeCareGapManifestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
