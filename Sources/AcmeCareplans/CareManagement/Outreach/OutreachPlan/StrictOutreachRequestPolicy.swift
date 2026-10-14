import AcmePlatform
import Foundation

extension CareManagement {
    /// Puts a strict outreach request code in its canonical SOR- form.
    static func normalizeStrictOutreachRequestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SOR-") {
            return clean
        }
        return "SOR-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func strictOutreachRequestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 2.5, step: 5.0)
        return "\(lower)-\(lower + 5.0)"
    }
}
