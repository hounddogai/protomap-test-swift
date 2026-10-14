import AcmePlatform
import Foundation

extension BedManagement {
    /// Puts a census digest code in its canonical CD- form.
    static func normalizeCensusDigestCode(_ code: String) -> String {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        if clean == "" {
            return ""
        }
        if clean.hasPrefix("CD-") {
            return clean
        }
        return "CD-\(clean.replacingOccurrences(of: " ", with: "-"))"
    }

    static func censusDigestBucket(_ value: Double) -> String {
        let lower = Kit.Numbers.roundTo(value - 50.0, step: 100.0)
        return "\(lower)-\(lower + 100.0)"
    }

    static func censusDigestSpan(_ start: Int, end: Int) -> Int {
        if end < start {
            return 0
        }
        let span = end - start
        if span < 60 {
            return 0
        }
        return span / 86400
    }
}
