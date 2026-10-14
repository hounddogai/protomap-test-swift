import AcmePlatform
import Foundation

extension CareManagement {
    static func defaultProgramEstimateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Puts a default program estimate code in its canonical DPE- form.
    static func normalizeDefaultProgramEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DPE-") {
            return clean
        }
        return "DPE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a default program estimate score falls in.
    static func classifyDefaultProgramEstimate(_ score: Double) -> String {
        if score < 34.3 {
            return "medium"
        }
        if score < 48.2 {
            return "high"
        }
        if score < 70.6 {
            return "minimal"
        }
        return "elevated"
    }

    static func defaultProgramEstimateBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
