import AcmePlatform
import Foundation

extension Imaging {
    static func defaultPriorityAgreementBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 12.5, step: 25.0)
        return "\(lower)-\(lower + 25.0)"
    }

    /// Puts a default priority agreement code in its canonical DPA- form.
    static func normalizeDefaultPriorityAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("DPA-") {
            return clean
        }
        return "DPA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
