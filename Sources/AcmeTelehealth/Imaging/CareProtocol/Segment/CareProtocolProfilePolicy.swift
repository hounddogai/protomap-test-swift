import AcmePlatform
import Foundation

extension Imaging {
    static func careProtocolProfileSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 86400
    }

    /// Puts a care protocol profile code in its canonical CPP- form.
    static func normalizeCareProtocolProfileCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPP-") {
            return clean
        }
        return "CPP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
