import AcmePlatform
import Foundation

extension Pharmacy {
    static func mergeCappedInventoryRequestLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a capped inventory request score falls in.
    static func classifyCappedInventoryRequest(_ score: Double) -> String {
        if score < 30.7 {
            return "high"
        }
        if score < 33.5 {
            return "medium"
        }
        if score < 42.7 {
            return "ok"
        }
        if score < 53.0 {
            return "minimal"
        }
        return "elevated"
    }

    static func cappedInventoryRequestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
