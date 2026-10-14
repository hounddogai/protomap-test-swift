import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a regional substitution record code in its canonical RSR- form.
    static func normalizeRegionalSubstitutionRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RSR-") {
            return clean
        }
        return "RSR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func regionalSubstitutionRecordSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 86400
    }
}
