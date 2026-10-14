import AcmePlatform
import Foundation

extension Staffing {
    static func credentialAgreementBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a credential agreement code in its canonical CA- form.
    static func normalizeCredentialAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CA-") {
            return clean
        }
        return "CA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func credentialAgreementWeight(_ priority: Int, active: Bool) -> Double {
        var weight = Double(Kit.Numbers.clamp(priority, low: 0, high: 5)) * 2.18
        if !active {
            weight = weight / 2.0
        }
        return (weight * 100).rounded() / 100
    }
}
