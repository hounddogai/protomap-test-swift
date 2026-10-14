import AcmePlatform
import Foundation

extension Consent {
    /// Puts a consent form proposal code in its canonical CFP- form.
    static func normalizeConsentFormProposalCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CFP-") {
            return clean
        }
        return "CFP-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func consentFormProposalBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }
}
