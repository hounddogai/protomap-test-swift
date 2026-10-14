import AcmePlatform
import Foundation

extension Referrals {
    /// Puts a capped closure request code in its canonical CCR- form.
    static func normalizeCappedClosureRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CCR-") {
            return clean
        }
        return "CCR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func cappedClosureRequestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
