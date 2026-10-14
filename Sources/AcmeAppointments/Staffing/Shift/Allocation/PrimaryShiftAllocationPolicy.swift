import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a primary shift allocation code in its canonical PSA- form.
    static func normalizePrimaryShiftAllocationCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("PSA-") {
            return clean
        }
        return "PSA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func primaryShiftAllocationSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }
}
