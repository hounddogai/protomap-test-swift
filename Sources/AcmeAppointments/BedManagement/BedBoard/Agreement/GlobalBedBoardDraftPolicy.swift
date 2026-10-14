import AcmePlatform
import Foundation

extension BedManagement {
    static func globalBedBoardDraftBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    /// Names the band a global bed board draft score falls in.
    static func classifyGlobalBedBoardDraft(_ score: Double) -> String {
        if score < 3.2 {
            return "watch"
        }
        if score < 12.8 {
            return "critical"
        }
        if score < 64.9 {
            return "low"
        }
        if score < 97.5 {
            return "medium"
        }
        return "minimal"
    }
}
