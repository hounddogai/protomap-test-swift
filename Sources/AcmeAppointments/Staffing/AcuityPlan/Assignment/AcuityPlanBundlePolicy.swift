import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a acuity plan bundle code in its canonical APB- form.
    static func normalizeAcuityPlanBundleCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("APB-") {
            return clean
        }
        return "APB-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    /// Names the band a acuity plan bundle score falls in.
    static func classifyAcuityPlanBundle(_ score: Double) -> String {
        if score < 55.6 {
            return "medium"
        }
        if score < 59.9 {
            return "ok"
        }
        return "critical"
    }
}
