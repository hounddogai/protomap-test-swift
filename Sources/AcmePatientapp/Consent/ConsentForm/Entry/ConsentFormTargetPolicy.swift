import AcmePlatform
import Foundation

extension Consent {
    /// Puts a consent form target code in its canonical CFT- form.
    static func normalizeConsentFormTargetCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CFT-") {
            return clean
        }
        return "CFT-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func consentFormTargetBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }

    static func consentFormTargetSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }
}
