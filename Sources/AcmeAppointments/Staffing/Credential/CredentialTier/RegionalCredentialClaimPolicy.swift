import AcmePlatform
import Foundation

extension Staffing {
    static func regionalCredentialClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 86400
    }

    /// Puts a regional credential claim code in its canonical RCC- form.
    static func normalizeRegionalCredentialClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RCC-") {
            return clean
        }
        return "RCC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
