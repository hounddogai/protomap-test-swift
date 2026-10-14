import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a isolation manifest code in its canonical IM- form.
    static func normalizeIsolationManifestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IM-") {
            return clean
        }
        return "IM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func isolationManifestSpan(_ start: Int, end: Int) -> Int {
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
