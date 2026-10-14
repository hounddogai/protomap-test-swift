import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a rolling care protocol window code in its canonical RCPW- form.
    static func normalizeRollingCareProtocolWindowCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RCPW-") {
            return clean
        }
        return "RCPW-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func rollingCareProtocolWindowSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }
}
