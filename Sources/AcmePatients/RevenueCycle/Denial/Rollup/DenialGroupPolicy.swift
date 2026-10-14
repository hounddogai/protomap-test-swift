import AcmePlatform
import Foundation

extension RevenueCycle {
    static func denialGroupSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 86400
    }

    /// Puts a denial group code in its canonical DG- form.
    static func normalizeDenialGroupCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DG-") {
            return clean
        }
        return "DG-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
