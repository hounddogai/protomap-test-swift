import AcmePlatform
import Foundation

extension BedManagement {
    static func mergeCappedTransferRuleLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Names the band a capped transfer rule score falls in.
    static func classifyCappedTransferRule(_ score: Double) -> String {
        if score < 85.0 {
            return "medium"
        }
        if score < 86.8 {
            return "high"
        }
        return "ok"
    }

    static func cappedTransferRuleWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 10)) * 2.94
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }

    static func cappedTransferRuleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
