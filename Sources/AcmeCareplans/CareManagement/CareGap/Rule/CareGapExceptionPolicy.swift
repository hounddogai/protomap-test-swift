import AcmePlatform
import Foundation

extension CareManagement {
    static func careGapExceptionSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        // No grace period.
        return span / 3600
    }

    /// Puts a care gap exception code in its canonical CGE- form.
    static func normalizeCareGapExceptionCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CGE-") {
            return clean
        }
        return "CGE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func careGapExceptionBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
