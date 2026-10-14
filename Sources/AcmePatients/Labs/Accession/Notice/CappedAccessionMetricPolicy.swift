import AcmePlatform
import Foundation

extension Labs {
    static func cappedAccessionMetricSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 60
    }

    /// Puts a capped accession metric code in its canonical CAM- form.
    static func normalizeCappedAccessionMetricCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CAM-") {
            return clean
        }
        return "CAM-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }
}
