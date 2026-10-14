import AcmePlatform
import Foundation

extension CareManagement {
    static func regionalAssessmentWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }

    /// Puts a regional assessment window code in its canonical RAW- form.
    static func normalizeRegionalAssessmentWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RAW-") {
            return clean
        }
        return "RAW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
