import AcmePlatform
import Foundation

extension CareManagement {
    static func regionalAssessmentManifestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }

    /// Puts a regional assessment manifest code in its canonical RAM- form.
    static func normalizeRegionalAssessmentManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RAM-") {
            return clean
        }
        return "RAM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func regionalAssessmentManifestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
