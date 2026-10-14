import AcmePlatform
import Foundation

extension Labs {
    /// Puts a courier request code in its canonical CR- form.
    static func normalizeCourierRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CR-") {
            return clean
        }
        return "CR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func courierRequestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 60
    }
}
