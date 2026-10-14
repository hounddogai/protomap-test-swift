import AcmePlatform
import Foundation

extension Staffing {
    /// Puts a strict overtime agreement code in its canonical SOA- form.
    static func normalizeStrictOvertimeAgreementCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("SOA-") {
            return clean
        }
        return "SOA-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func strictOvertimeAgreementSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 900 {
            return 0
        }
        return span / 60
    }
}
