import AcmePlatform
import Foundation

extension Pharmacy {
    /// Puts a adaptive interaction record code in its canonical AIR- form.
    static func normalizeAdaptiveInteractionRecordCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("AIR-") {
            return clean
        }
        return "AIR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func adaptiveInteractionRecordSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }
}
