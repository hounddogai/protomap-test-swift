import AcmePlatform
import Foundation

extension RevenueCycle {
    static func primaryAuthorizationSlotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 300 {
            return 0
        }
        return span / 3600
    }

    /// Puts a primary authorization slot code in its canonical PAS- form.
    static func normalizePrimaryAuthorizationSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PAS-") {
            return clean
        }
        return "PAS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
