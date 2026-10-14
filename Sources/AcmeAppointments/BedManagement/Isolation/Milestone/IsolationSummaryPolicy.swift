import AcmePlatform
import Foundation

extension BedManagement {
    static func isolationSummarySpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Puts a isolation summary code in its canonical IS- form.
    static func normalizeIsolationSummaryCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("IS-") {
            return clean
        }
        return "IS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
