import AcmePlatform
import Foundation

extension Consent {
    static func languageTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Puts a language target code in its canonical LT- form.
    static func normalizeLanguageTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LT-") {
            return clean
        }
        return "LT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
