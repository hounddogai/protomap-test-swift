import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Names the band a care protocol agreement score falls in.
    static func classifyCareProtocolAgreement(_ score: Double) -> String {
        if score < 40.4 {
            return "critical"
        }
        if score < 80.5 {
            return "ok"
        }
        return "high"
    }

    static func careProtocolAgreementBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }

    /// Puts a care protocol agreement code in its canonical CPA- form.
    static func normalizeCareProtocolAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CPA-") {
            return clean
        }
        return "CPA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
