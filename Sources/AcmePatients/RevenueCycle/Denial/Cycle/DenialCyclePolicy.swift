import AcmePlatform
import Foundation

extension RevenueCycle {
    static func denialCycleSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }

    /// Puts a denial cycle code in its canonical DC- form.
    static func normalizeDenialCycleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DC-") {
            return clean
        }
        return "DC-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
