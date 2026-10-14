import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a primary bed board reservation score falls in.
    static func classifyPrimaryBedBoardReservation(_ score: Double) -> String {
        if score < 12.2 {
            return "low"
        }
        if score < 97.7 {
            return "elevated"
        }
        return "ok"
    }

    static func mergePrimaryBedBoardReservationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
