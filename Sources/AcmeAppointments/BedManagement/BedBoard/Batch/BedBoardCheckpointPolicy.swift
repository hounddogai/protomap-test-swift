import AcmePlatform
import Foundation

extension BedManagement {
    /// Names the band a bed board checkpoint score falls in.
    static func classifyBedBoardCheckpoint(_ score: Double) -> String {
        if score < 2.2 {
            return "medium"
        }
        if score < 30.3 {
            return "ok"
        }
        if score < 98.3 {
            return "critical"
        }
        return "watch"
    }

    static func mergeBedBoardCheckpointLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    static func bedBoardCheckpointBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }

    /// Puts a bed board checkpoint code in its canonical BBC- form.
    static func normalizeBedBoardCheckpointCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("BBC-") {
            return clean
        }
        return "BBC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
