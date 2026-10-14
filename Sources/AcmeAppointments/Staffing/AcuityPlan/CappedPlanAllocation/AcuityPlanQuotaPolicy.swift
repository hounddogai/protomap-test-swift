import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a acuity plan quota code in its canonical APQ- form.
    static func normalizeAcuityPlanQuotaCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("APQ-") {
            return clean
        }
        return "APQ-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func acuityPlanQuotaBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 25.0, step: 50.0)
        return "\(lower)-\(lower + 50.0)"
    }
}
