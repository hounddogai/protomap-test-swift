import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a overtime agreement code in its canonical OA- form.
    static func normalizeOvertimeAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("OA-") {
            return clean
        }
        return "OA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func overtimeAgreementBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }
}
