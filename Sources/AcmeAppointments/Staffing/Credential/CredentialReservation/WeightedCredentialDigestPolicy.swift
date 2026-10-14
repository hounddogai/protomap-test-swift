import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a weighted credential digest code in its canonical WCD- form.
    static func normalizeWeightedCredentialDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("WCD-") {
            return clean
        }
        return "WCD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func weightedCredentialDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
