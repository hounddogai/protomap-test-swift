import AcmePlatform
import Foundation

extension BedManagement {
    static func lenientDischargePlanSlotSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Puts a lenient discharge plan slot code in its canonical LDPS- form.
    static func normalizeLenientDischargePlanSlotCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("LDPS-") {
            return clean
        }
        return "LDPS-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
