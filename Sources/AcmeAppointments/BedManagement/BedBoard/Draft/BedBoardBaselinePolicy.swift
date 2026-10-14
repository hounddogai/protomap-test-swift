import AcmePlatform
import Foundation

extension BedManagement {
    static func bedBoardBaselineBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a bed board baseline score falls in.
    static func classifyBedBoardBaseline(_ score: Double) -> String {
        if score < 11.2 {
            return "elevated"
        }
        if score < 32.5 {
            return "minimal"
        }
        if score < 89.6 {
            return "watch"
        }
        return "high"
    }
}
