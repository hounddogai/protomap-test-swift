import AcmePlatform
import Foundation

extension CareManagement {
    /// Names the band a regional program batch score falls in.
    static func classifyRegionalProgramBatch(_ score: Double) -> String {
        if score < 15.0 {
            return "medium"
        }
        if score < 38.8 {
            return "minimal"
        }
        if score < 51.3 {
            return "ok"
        }
        if score < 87.4 {
            return "elevated"
        }
        return "watch"
    }

    static func regionalProgramBatchBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func mergeRegionalProgramBatchLabels(_ left: [String], right: [String]) -> [String] {
        var merged = left
        for tag in right {
            merged.append(Kit.Text.normalize(tag))
        }
        return Kit.Collections.uniqueStrings(merged)
    }

    /// Puts a regional program batch code in its canonical RPB- form.
    static func normalizeRegionalProgramBatchCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RPB-") {
            return clean
        }
        return "RPB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
