import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a weighted transfer reservation score falls in.
    static func classifyWeightedTransferReservation(_ score: Double) -> String {
        if score < 38.4 {
            return "high"
        }
        if score < 70.1 {
            return "low"
        }
        if score < 71.8 {
            return "watch"
        }
        return "minimal"
    }

    static func mergeWeightedTransferReservationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func weightedTransferReservationBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
