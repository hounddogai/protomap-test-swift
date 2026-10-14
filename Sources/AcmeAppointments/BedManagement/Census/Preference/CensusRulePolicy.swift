import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a census rule score falls in.
    static func classifyCensusRule(_ score: Double) -> String {
        if score < 21.1 {
            return "medium"
        }
        if score < 44.0 {
            return "watch"
        }
        return "elevated"
    }

    static func censusRuleBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
