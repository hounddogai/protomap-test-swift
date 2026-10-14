import AcmePlatform
import Foundation

extension Labs {
    /// Puts a primary accession claim code in its canonical PAC- form.
    static func normalizePrimaryAccessionClaimCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PAC-") {
            return clean
        }
        return "PAC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func primaryAccessionClaimSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }
}
