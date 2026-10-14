import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a care protocol reservation score falls in.
    static func classifyCareProtocolReservation(_ score: Double) -> String {
        if score < 2.9 {
            return "high"
        }
        if score < 43.1 {
            return "watch"
        }
        return "ok"
    }

    static func mergeCareProtocolReservationLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }
}
