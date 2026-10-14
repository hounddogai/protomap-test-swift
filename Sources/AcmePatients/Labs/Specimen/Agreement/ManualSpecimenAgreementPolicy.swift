import AcmePlatform
import Foundation

extension Labs {
    /// Names the band a manual specimen agreement score falls in.
    static func classifyManualSpecimenAgreement(_ score: Double) -> String {
        if score < 11.1 {
            return "ok"
        }
        if score < 58.2 {
            return "minimal"
        }
        return "elevated"
    }

    static func manualSpecimenAgreementBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 5.0, step: 10.0)
        return "\(lower)-\(lower + 10.0)"
    }
}
