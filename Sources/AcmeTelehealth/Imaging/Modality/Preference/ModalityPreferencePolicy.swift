import AcmePlatform
import Foundation

extension Imaging {
    /// Puts a modality preference code in its canonical MP- form.
    static func normalizeModalityPreferenceCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("MP-") {
            return clean
        }
        return "MP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func modalityPreferenceSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}
