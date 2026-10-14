import AcmePlatform
import Foundation

extension Imaging {
    static func readExceptionSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 60
    }

    /// Puts a read exception code in its canonical RE- form.
    static func normalizeReadExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("RE-") {
            return clean
        }
        return "RE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
