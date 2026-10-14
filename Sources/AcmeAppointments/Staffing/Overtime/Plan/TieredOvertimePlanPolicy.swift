import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a tiered overtime plan code in its canonical TOP- form.
    static func normalizeTieredOvertimePlanCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("TOP-") {
            return clean
        }
        return "TOP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func tieredOvertimePlanSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }
}
