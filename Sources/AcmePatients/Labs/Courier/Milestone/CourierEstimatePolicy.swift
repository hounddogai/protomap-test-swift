import AcmePlatform
import Foundation

extension Labs {
    static func courierEstimateSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 3600 {
            return 0
        }
        return span / 3600
    }

    /// Puts a courier estimate code in its canonical CE- form.
    static func normalizeCourierEstimateCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CE-") {
            return clean
        }
        return "CE-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
